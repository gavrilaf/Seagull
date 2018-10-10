import Foundation
import NIO
import NIOHTTP1

// MARK: -
extension Channel {
    public func syncCloseAcceptingAlreadyClosed() throws {
        do {
            try self.close().wait()
        } catch ChannelError.alreadyClosed {
            /* we're happy with this one */
        } catch let e {
            throw e
        }
    }
}

// MARK: -
extension Array where Array.Element == ByteBuffer {
    public func allAsBytes() -> [UInt8] {
        var out: [UInt8] = []
        out.reserveCapacity(self.reduce(0, { $0 + $1.readableBytes }))
        self.forEach { bb in
            bb.withUnsafeReadableBytes { ptr in
                out.append(contentsOf: ptr)
            }
        }
        return out
    }
    
    public func allAsString() -> String? {
        return String(decoding: self.allAsBytes(), as: UTF8.self)
    }
}

// MARK: -
open class ArrayAccumulationHandler<T>: ChannelInboundHandler {
    public typealias InboundIn = T
    
    private var receiveds: [T] = []
    private var allDoneBlock: DispatchWorkItem! = nil
    
    public init(completion: @escaping ([T]) -> Void) {
        self.allDoneBlock = DispatchWorkItem { [unowned self] () -> Void in
            completion(self.receiveds)
        }
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        self.receiveds.append(self.unwrapInboundIn(data))
    }
    
    public func channelUnregistered(ctx: ChannelHandlerContext) {
        self.allDoneBlock.perform()
    }
    
    public func syncWaitForCompletion() {
        self.allDoneBlock.wait()
    }
}


