import XCTest
import Vapor
@testable import AMKit

final class AMKitTests: XCTestCase {
    func testPreEncode() throws {
        let app = Application()
        let context = Context()
        let entity = PreEncoded("hello", context: context)
        _ = try JSONEncoder().encode(entity)
        XCTAssertFalse(context.encoded)
        try preEncode(entity, for: Request(application: app, on: app.eventLoopGroup.next())).wait()
        XCTAssertTrue(context.encoded)
        app.shutdown()
    }
    
    func testNestedPreEncode() throws {
        let app = Application()
        let context = Context()
        
        struct Entity: Encodable {
            let value: PreEncoded<String>
        }
        
        let entity = Entity(value: .init("hello", context: context))
        _ = try JSONEncoder().encode(entity)
        XCTAssertFalse(context.encoded)
        try preEncode(entity, for: Request(application: app, on: app.eventLoopGroup.next())).wait()
        XCTAssertTrue(context.encoded)
        app.shutdown()
    }

    static var allTests = [
        ("testExample", testPreEncode),
    ]
}

final class Context {
    var preencode = true
    var encoded = false
    
    init() {}
}

struct PreEncoded<C: Encodable>: PreEncodable {
    let value: C
    let context: Context
    
    init(_ value: C, context: Context) {
        self.value = value
        self.context = context
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
    
    func shouldPreEncode(for request: Request) -> Bool {
        return context.preencode
    }
    
    func preEncode(for request: Request) -> EventLoopFuture<Void> {
        context.encoded = true
        return request.eventLoop.future()
    }
}
