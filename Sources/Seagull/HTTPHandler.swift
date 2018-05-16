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
    private let router: Router
    
    private var preparedRequest: PreparedRequest?
    
    public init(router: Router, fileIO: NonBlockingFileIO) {
        self.router = router
        self.fileIO = fileIO
    }
    
    // MARK: -
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        if self.preparedRequest != nil { // Route handler already initialized, just continue processing
            handlerReqPart(ctx: ctx, reqPart: reqPart)
            return
        }
        
        switch reqPart {
        case .head(let head):
            let res = router.lookup(method: head.method, uri: head.uri)
            switch res {
            case .success(let preparedRequest):
                self.preparedRequest = preparedRequest
                handlerReqPart(ctx: ctx, reqPart: reqPart)
            case .failure(let err):
                self.keepAlive = head.isKeepAlive
                self.state.requestReceived()
                sendErrorResponse(ctx: ctx, head: head, error: err)
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
        case .head(let request):
            self.savedRequestHead = request
            self.keepAlive = request.isKeepAlive
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
        guard let head = self.savedRequestHead, let preparedRequest = self.preparedRequest else {
            fatalError("Something wrong, should never happens")
        }
        
        let sgRequest = SgRequest.from(preparedRequest: preparedRequest, head: head, body: savedBody)
        let result = preparedRequest.handler(sgRequest, SgRequestContext())
        
        switch result {
        case .data(let response):
            sendDataResponse(ctx: ctx, head: head, response: response)
        case .file(let response):
            sendFileResponse(ctx: ctx, head: head, response: response)
        case .error(let error):
            sendErrorResponse(ctx: ctx, head: head, error: error)
        }
    }
    
    private func sendDataResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, response: SgDataResponse) {
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
    }
    
    private func sendFileResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, response: SgFileResponse) {
        let fileHandle = self.fileIO.openFile(path: response.path, eventLoop: ctx.eventLoop)
        
        func responseHead(request: HTTPRequestHead, fileRegion region: FileRegion) -> HTTPResponseHead {
            var response = httpResponseHead(request: request, status: .ok)
            response.headers.add(name: "Content-Length", value: "\(region.endIndex)")
            response.headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
            return response
        }
        
        fileHandle.whenFailure {
            self.sendErrorResponse(ctx: ctx, head: head, error: $0)
        }
        
        fileHandle.whenSuccess { (file, region) in
            var responseStarted = false
            let response = responseHead(request: head, fileRegion: region)
            return self.fileIO.readChunked(fileRegion: region,
                                           chunkSize: 32 * 1024,
                                           allocator: ctx.channel.allocator,
                                           eventLoop: ctx.eventLoop) { buffer in
                                                if !responseStarted {
                                                    responseStarted = true
                                                    ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                                                }
                                                return ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
                    }.then { () -> EventLoopFuture<Void> in
                        let p: EventLoopPromise<Void> = ctx.eventLoop.newPromise()
                        self.completeResponse(ctx, trailers: nil, promise: p)
                        return p.futureResult
                    }.thenIfError { error in
                        if !responseStarted {
                            let response = httpResponseHead(request: head, status: .ok)
                            ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                            var buffer = ctx.channel.allocator.buffer(capacity: 100)
                            buffer.write(string: "fail: \(error)")
                            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                            self.state.responseComplete()
                            return ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)))
                        } else {
                            return ctx.close()
                        }
                    }.whenComplete {
                        _ = try? file.close()
                }
        }
    }
    
    private func sendErrorResponse(ctx: ChannelHandlerContext, head: HTTPRequestHead, error: Error) {
        var body = ctx.channel.allocator.buffer(capacity: 128)
        let response = { () -> HTTPResponseHead in
            switch error {
            case let e as SgErrorResponse:
                if let respBody = e.response.body {
                    body.write(bytes: respBody)
                }
                return httpResponseHead(request: head, status: e.response.code, headers: e.response.headers)
            default:
                body.write(string: "Error: \(type(of: error)) error\r\n")
                return httpResponseHead(request: head, status: .internalServerError)
            }
        }()
        
        ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
        ctx.write(self.wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
        ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        
        ctx.channel.close(promise: nil)
    }
    
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()
        
        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
        
        self.preparedRequest = nil
    }
}

