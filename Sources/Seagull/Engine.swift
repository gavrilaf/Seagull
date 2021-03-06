import NIO
import NIOHTTP1

public enum EngineError: Error {
    case bindError
}

public class Engine {
    
    public init(router: HttpRouter, logger: LogProtocol = DefaultLogger(), errorProvider: ErrorProvider = DefaultErrorProvider()) {
        self.router = router
        self.logger = logger
        self.errorProvider = errorProvider
    }
    
    public func run(host: String, port: Int) throws {
        logger.info("Seagull engine starting....")
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let threadPool = BlockingIOThreadPool(numberOfThreads: 6)
        threadPool.start()
        
        let fileIO = NonBlockingFileIO(threadPool: threadPool)
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then { [weak self] in
                    guard let sself = self else {
                        fatalError("Seagull engine is nil")
                    }
                    return channel.pipeline.add(handler: HTTPHandler(router: sself.router,
                                                                     fileIO: fileIO,
                                                                     logger: sself.logger,
                                                                     errorProvider: sself.errorProvider))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        let channel = try { () -> Channel in
            return try bootstrap.bind(host: host, port: port).wait()
        }()
        
        if channel.localAddress == nil {
            throw EngineError.bindError
        }
        
        self.threadGroup = group
        self.channel = channel
        
        logger.info("Server started and listening on \(String(describing: self.localAddress))")
    }
    
    public var localAddress: SocketAddress? {
        return channel?.localAddress
    }
    
    public func close() throws {
        try channel?.close().wait()
        try threadGroup?.syncShutdownGracefully()
    }
    
    public func waitForCompletion() throws {
        try channel?.closeFuture.wait()
    }
    
    // MARK: -
    
    private let router: HttpRouter
    
    private let logger: LogProtocol
    private let errorProvider: ErrorProvider
    
    private var threadGroup: MultiThreadedEventLoopGroup?
    private var channel: Channel?
}


