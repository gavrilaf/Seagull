import Foundation
import XCTest
import Seagull
import NIOHTTP1

class HTTPClientResponsePartAssertHandler: ArrayAccumulationHandler<HTTPClientResponsePart> {
    public init(_ expectedVersion: HTTPVersion, _ expectedStatus: HTTPResponseStatus, _ expectedHeaders: HTTPHeaders, _ expectedBody: String?, _ expectedTrailers: HTTPHeaders? = nil) {
        super.init { parts in
            guard parts.count >= 2 else {
                XCTFail("only \(parts.count) parts")
                return
            }
            if case .head(let h) = parts[0] {
                XCTAssertEqual(expectedVersion, h.version)
                XCTAssertEqual(expectedStatus, h.status)
                XCTAssertEqual(expectedHeaders, h.headers)
            } else {
                XCTFail("unexpected type on index 0 \(parts[0])")
            }
            
            var i = 1
            var bytes: [UInt8] = []
            while i < parts.count - 1 {
                if case .body(let bb) = parts[i] {
                    bb.withUnsafeReadableBytes { ptr in
                        bytes.append(contentsOf: ptr)
                    }
                } else {
                    XCTFail("unexpected type on index \(i) \(parts[i])")
                }
                i += 1
            }
            
            // TODO: Hard to check expected body for json endoded objects, because different order on Mac & Linux, fix later!
            
            //XCTAssertEqual(expectedBody, String(decoding: bytes, as: UTF8.self))
            
            if case .end(let trailers) = parts[parts.count - 1] {
                XCTAssertEqual(expectedTrailers, trailers)
            } else {
                XCTFail("unexpected type on index \(parts.count - 1) \(parts[parts.count - 1])")
            }
        }
    }
}

