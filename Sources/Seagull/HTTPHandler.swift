import NIO
import NIOHTTP1

private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }
    
    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
        
        switch (request.isKeepAlive, request.version.major, request.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}


final class HTTPHandler: ChannelInboundHandler {
    
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private let initialBufferCapacity = 100
    
    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse
        
        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }
        
        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }
        
        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }
    
    private var keepAlive = false
    private var state = State.idle
    
    private var savedRequestHead: HTTPRequestHead?
    private var savedBody: ByteBuffer?
    
    private let fileIO: NonBlockingFileIO
    private let router: HttpRouter
    private let logger: LogProtocol
    private let errorProvider: ErrorProvider
    
    private var routeHandler: RouteHandler?
    
    init(router: HttpRouter, fileIO: NonBlockingFileIO, logger: LogProtocol, errorProvider: ErrorProvider) {
        self.router = router
        self.fileIO = fileIO
        self.logger = logger
        self.errorProvider = errorProvider
    }
    
    // MARK: -
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        if self.routeHandler != nil { // Route handler already initialized, just continue processing
            handlerReqPart(ctx: ctx, reqPart: reqPart)
            return
        }
        
        switch reqPart {
        case .head(let head):
            let res = router.lookup(uri: head.uri, method: head.method)
            switch res {
            case .success(let handler):
                self.routeHandler = handler
                handlerReqPart(ctx: ctx, reqPart: reqPart)
            case .failure(let err):
                self.keepAlive = head.isKeepAlive
                self.state.requestReceived()
                logRouterError(err, head: head)
                _ = sendErrorResponse(ctx: ctx, head: head, error: err)
            }
            
        case .body:
            break
            
        case .end:
            self.state.requestComplete()
        }
    }
    
    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    func handlerAdded(ctx: ChannelHandlerContext) {
        
    }
    
    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                ctx.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            ctx.fireUserInboundEventTriggered(event)
        }
    }
    
    // MARK: -
    private func handlerReqPart(ctx: ChannelHandlerContext, reqPart: HTTPServerRequestPart) {
        switch reqPart {
        case .head(let head):
            self.savedRequestHead = head
            self.keepAlive = head.isKeepAlive
            self.state.requestReceived()
            
        case .body(var buf):
            if buf.readableBytes > 0 {
                if self.savedBody == nil {
                    self.savedBody = ctx.channel.allocator.buffer(capacity: buf.readableBytes)
                }
                self.savedBody?.write(buffer: &buf)
            }
            
        case .end:
            self.state.requestComplete()
            handleRequest(ctx: ctx)
        }
    }
    
    private func handleRequest(ctx: ChannelHandlerContext) {
        guard let head = self.savedRequestHead, let routeHandler = self.routeHandler else {
            fatalError("Something wrong, should never happens")
        }
        
        let request = SgRequest(route: routeHandler.parsedRoute, extra: RequestExtra.make(from: head, body: savedBody))
        let context = SgRequestContext(logger: logger, errorProvider: errorProvider)
        let result = routeHandler.handle(request: request, with: context)
        
        let sendResult: EventLoopFuture<SgError?>
        switch result {
        case .data(let response):
            sendResult = sendDataResponse(ctx: ctx, head: head, response: response)
        case .file(let response):
            sendResult = sendFileResponse(ctx: ctx, head: head, response: response)
        case .error(let error):
            sendResult = sendErrorResponse(ctx: ctx, head: head, error: error)
        }
        
        sendResult.whenSuccess { (sendError) in
            self.logRequest(request: request, result: result, sendError: sendError)
        }
    }
    
    // MARK: -
    private func sendDataResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, response: SgDataResponse) -> EventLoopFuture<SgError?> {
        var headers = response.headers
        var buffer: ByteBuffer?
        
        if let body = response.body {
            buffer = ctx.channel.allocator.buffer(capacity: body.count)
            buffer?.write(bytes: body)
            headers.add(name: "Content-Length", value: "\(body.count)")
        }
        
        ctx.write(self.wrapOutboundOut(.head(httpResponseHead(request: head, status: response.code, headers: headers))), promise: nil)
        if let buffer = buffer {
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
        
        self.completeResponse(ctx, trailers: nil, promise: nil)
        
        let result: EventLoopPromise<SgError?> = ctx.eventLoop.newPromise()
        result.succeed(result: nil)
        return result.futureResult
    }
    
    private func sendFileResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, response: SgFileResponse) -> EventLoopFuture<SgError?> {
        let result: EventLoopPromise<SgError?> = ctx.eventLoop.newPromise()
        let fileHandle = self.fileIO.openFile(path: response.path, eventLoop: ctx.eventLoop)
        
        fileHandle.whenFailure {
            let error = FileError.notFound(path: response.path, err: $0)
            _ = self.sendErrorResponse(ctx: ctx, head: head, error: error)
            result.succeed(result: error)
        }
        
        fileHandle.whenSuccess { (file, region) in
            var responseStarted = false
            let responseHead: HTTPResponseHead = {
                var response = httpResponseHead(request: head, status: .ok, headers: response.headers)
                response.headers.add(name: "Content-Length", value: "\(region.endIndex)")
                return response
            }()
            
            return self.fileIO.readChunked(fileRegion: region, chunkSize: 32 * 1024, allocator: ctx.channel.allocator, eventLoop: ctx.eventLoop) { buffer in
                if !responseStarted {
                    responseStarted = true
                    ctx.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
                }
                return ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
            }.then { () -> EventLoopFuture<Void> in
                let p: EventLoopPromise<Void> = ctx.eventLoop.newPromise()
                self.completeResponse(ctx, trailers: nil, promise: p)
                result.succeed(result: nil)
                return p.futureResult
            }.thenIfError {
                let error = FileError.ioError(path: response.path, err: $0)
                if !responseStarted {
                    _ = self.sendErrorResponse(ctx: ctx, head: head, error: error)
                }
                result.succeed(result: error)
                return ctx.close()
            }.whenComplete {
                _ = try? file.close()
            }
        }
        
        return result.futureResult
    }
    
    private func sendErrorResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, error: Error) -> EventLoopFuture<SgError?> {
        let response = errorProvider.convert(error: error).response
        
        var headers = response.headers
        var buffer: ByteBuffer?
        
        if let body = response.body {
            buffer = ctx.channel.allocator.buffer(capacity: body.count)
            buffer?.write(bytes: body)
            headers.add(name: "Content-Length", value: "\(body.count)")
        }
        
        let respHead = httpResponseHead(request: head, status: response.code, headers: headers)
        
        ctx.write(self.wrapOutboundOut(.head(respHead)), promise: nil)
        if let buffer = buffer {
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        ctx.channel.close(promise: nil)
        
        let result: EventLoopPromise<SgError?> = ctx.eventLoop.newPromise()
        result.succeed(result: nil)
        return result.futureResult
    }
    
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()
        
        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
        
        self.savedBody = nil
        self.routeHandler = nil
    }
    
    // MARK: -
    private func logRouterError(_ err: SgError, head: HTTPRequestHead) {
        logger.error("\(head.method) \(head.uri), \(err.httpCode), \(err)")
    }
    
    private func logRequest(request: SgRequest, result: SgResult, sendError: SgError?) {
        let responseCode = result.httpCode
        let route = request.route
        
        if responseCode.code < 400 {
            if let sendError = sendError {
                logger.error("\(route.method) \(route.uri), \(sendError.httpCode), \(sendError)")
            } else {
                logger.info("\(route.method) \(route.uri), \(responseCode)")
            }
        } else {
            if case let .error(errResp) = result, let err = errResp.error {
                logger.error("\(route.method) \(route.uri), \(responseCode), \(err)")
            } else {
                logger.error("\(route.method) \(route.uri), \(responseCode)")
            }
        }
    }
}

