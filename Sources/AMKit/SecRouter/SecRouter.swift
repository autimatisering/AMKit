import Vapor
import IkigaJSON

public struct SecuredEncodingPermissionError: Error {}

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
    
    func canEncode(for request: Request) -> EventLoopFuture<Bool>
}

extension EncodableExample {
    public static func makeExampleJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(example)
        return String(data: data, encoding: .utf8)!
    }
}

extension SecuredContent {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        if request.application.secRouterConfig?.preEncodeResponses == true {
            return encodeResponseWithPreEncoding(for: request)
        } else {
            return encodeResponseWithoutPreEncoding(for: request)
        }
    }
    
    private func encodeResponseWithPreEncoding(for request: Request) -> EventLoopFuture<Response> {
        return self.canEncode(for: request).flatMap { canEncode in
            guard canEncode else {
                let error = SecuredEncodingPermissionError()
                return request.eventLoop.makeFailedFuture(error)
            }
                
            return preEncode(self, for: request).flatMapThrowing {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                
                SecurityHelper.updateContext(in: &encoder.userInfo, forSubject: self)
                let context = try SecurityContext(from: request)
                encoder.userInfo[Self.securityContentKey] = context
                
                let response = Response()
                try response.content.encode(self, using: encoder)
                return response
            }
        }
    }
    
    public func encodeResponseWithoutPreEncoding(for request: Request) -> EventLoopFuture<Response> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            SecurityHelper.updateContext(in: &encoder.userInfo, forSubject: self)
            let context = try SecurityContext(from: request)
            
            encoder.userInfo[Self.securityContentKey] = context
            return self.canEncode(for: request).flatMapThrowing { canEncode in
                guard canEncode else {
                    throw SecuredEncodingPermissionError()
                }
                
                let response = Response()
                try response.content.encode(self, using: encoder)
                return response
            }
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
extension Array: SecuredResponseEncodable where Element: SecuredContent {}

extension Array: SecuredContent where Element: SecuredContent {
    public func canEncode(for request: Request) -> EventLoopFuture<Bool> {
        let canEncodeResults = map { $0.canEncode(for: request) }
        return EventLoopFuture.whenAllSucceed(canEncodeResults, on: request.eventLoop).map { canEncode in
            return canEncode.reduce(true) { $0 && $1 }
        }
    }
    
    public static var securityContentKey: CodingUserInfoKey {
        Element.securityContentKey
    }
    
    public typealias SecurityContext = Element.SecurityContext
}

extension Set: JSONDescribedResponse where Element: JSONDescribedResponse {
    public static func makeExampleJSON() throws -> String {
        try "[\(Element.makeExampleJSON())]"
    }
}

extension Set: SecuredResponseEncodable, SecuredContent, ResponseEncodable, RequestDecodable, Content where Element: SecuredContent {
    public func canEncode(for request: Request) -> EventLoopFuture<Bool> {
        let canEncodeResults = map { $0.canEncode(for: request) }
        return EventLoopFuture.whenAllSucceed(canEncodeResults, on: request.eventLoop).map { canEncode in
            return canEncode.reduce(true) { $0 && $1 }
        }
    }
    
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
