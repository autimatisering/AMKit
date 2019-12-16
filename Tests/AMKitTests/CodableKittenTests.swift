import XCTest
import IkigaJSON
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
    
    func testJSONDecodingErrors() throws {
        let object: JSONObject = [
            "firstName": "Joannis",
            "lastName": "Orlandos"
        ]
        
        struct FullUser: Decodable {
            let firstName: String
            let lastName: String
        }
        
        struct PartialUser: Decodable {
            let firstName: String
        }
        
        struct InvalidFullUser: Decodable {
            let firstName: Int
            let lastName: String
        }
        
        struct InvalidPartialUser: Decodable {
            let firstName: Int
        }
        
        var report = decodingErrors(for: FullUser.self, from: object)
        XCTAssertTrue(report.errors.isEmpty)
        XCTAssertTrue(report.unusedKeys.isEmpty)
        
        report = decodingErrors(for: PartialUser.self, from: object)
        XCTAssertTrue(report.errors.isEmpty)
        XCTAssertEqual(report.unusedKeys.count, 1)
        
        report = decodingErrors(for: InvalidFullUser.self, from: object)
        XCTAssertEqual(report.errors.count, 1)
        XCTAssertTrue(report.unusedKeys.isEmpty)
        
        report = decodingErrors(for: InvalidPartialUser.self, from: object)
        XCTAssertEqual(report.errors.count, 1)
        XCTAssertEqual(report.unusedKeys.count, 1)
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
