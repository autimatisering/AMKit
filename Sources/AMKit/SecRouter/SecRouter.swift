import Vapor
import IkigaJSON

public protocol JSONDescribedResponse {
    static func makeExampleJSON() throws -> String
}

public protocol EncodableExample: Encodable {
    static var example: Self { get }
}

public protocol DescribedParameter: CustomStringConvertible {
    
}

public protocol DescribedRequest {
    static func makeExampleJSON() throws -> String
}

public protocol SecuredResponseEncodable: JSONDescribedResponse {
    func encodeResponse(for request: Request) -> EventLoopFuture<Response>
}

public protocol SecuredResponseEncodingContext {
    init(from request: Request) throws
}

public protocol SecuredContent: Content, SecuredResponseEncodable {
    static var securityContentKey: CodingUserInfoKey { get }
    
    associatedtype SecurityContext: SecuredResponseEncodingContext
}

public protocol PreEncodedSecuredContent: SecuredContent {}

extension EncodableExample {
    public static func makeExampleJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(example)
        return String(data: data, encoding: .utf8)!
    }
}

extension PreEncodedSecuredContent {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        return preEncode(self, for: request).flatMapThrowing {
            var encoder = IkigaJSONEncoder()
            encoder.settings.dateDecodingStrategy = .iso8601
            
            SecurityHelper.updateContext(in: &encoder.userInfo, forSubject: self)
            encoder.userInfo[Self.securityContentKey] = try SecurityContext(from: request)
            
            let response = Response()
            try response.content.encode(self, using: encoder)
            return response
        }
    }
}

extension SecuredContent {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        var encoder = IkigaJSONEncoder()
        encoder.settings.dateDecodingStrategy = .iso8601
        
        do {
            SecurityHelper.updateContext(in: &encoder.userInfo, forSubject: self)
            encoder.userInfo[Self.securityContentKey] = try SecurityContext(from: request)
            
            let response = Response()
            try response.content.encode(self, using: encoder)
            return request.eventLoop.makeSucceededFuture(response)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

extension Array: JSONDescribedResponse where Element: JSONDescribedResponse {
    public static func makeExampleJSON() throws -> String {
        try "[\(Element.makeExampleJSON())]"
    }
}
extension Array: SecuredResponseEncodable, SecuredContent where Element: SecuredContent {
    public static var securityContentKey: CodingUserInfoKey {
        Element.securityContentKey
    }
    
    public typealias SecurityContext = Element.SecurityContext
}

extension Never: DescribedRequest {
    public static var example: Never { fatalError() }
    
    public static func makeExampleJSON() throws -> String {
        struct None: Error {}
        throw None()
    }
}

extension EventLoopFuture: JSONDescribedResponse where Value: JSONDescribedResponse {
    public static func makeExampleJSON() throws -> String {
        try Value.makeExampleJSON()
    }
}
extension EventLoopFuture: SecuredResponseEncodable where Value: SecuredResponseEncodable {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        self.flatMap { result in
            result.encodeResponse(for: request)
        }
    }
}

public final class RouteDescription {
    func describeRoute(_ route: Route) {
//        guard
//            let request = route.requestType as? DescribedRequest.Type,
//            let response = route.responseType as? SecuredResponseEncodable.Type
//        else {
//            return
//        }
    }
}
