import NIO
import NIOHTTP1


public struct Engine {
    public init() {}
    
    public func Run(router: Router) {
        print("Seagull engine starting....")
        
        let defaultHost = "::1"
        let defaultPort = 8006

        let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
        
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then {
                    channel.pipeline.add(handler: HTTPHandler(router: router))
                }
            }
            
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        let channel = try! { () -> Channel in
            return try bootstrap.bind(host: defaultHost, port: defaultPort).wait()
        }()
        
        guard let localAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
        
        // This will never unblock as we don't close the ServerChannel
        try! channel.closeFuture.wait()
        
        print("Server closed")
    }
}


