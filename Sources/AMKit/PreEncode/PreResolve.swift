import Vapor

public protocol PreResolvable {
    associatedtype Resolved: Codable
    
    static func shouldResolve(for request: Request, multiple: Bool) -> Bool
    func resolve(for request: Request) -> EventLoopFuture<Resolved?>
}

@propertyWrapper
fileprivate final class ReferenceContaner<T> {
    var wrappedValue: T
    
    init(_ value: T) {
        self.wrappedValue = value
    }
}

@propertyWrapper
public struct PreResolvedList<
    C: Codable & Collection, PR: PreResolvable
>: Codable, PreEncodable where C.Element == PR {
    public typealias Resolved = [PR.Resolved]
    
    public var wrappedValue: C
    @ReferenceContaner private var resolved: [PR.Resolved]?
    
    public init(_ value: C) {
        self.wrappedValue = value
        self._resolved = .init(nil)
    }
    
    public func shouldPreEncode(for request: Request) -> Bool {
        PR.shouldResolve(for: request, multiple: true)
    }
    
    public func preEncode(for request: Request) -> EventLoopFuture<Void> {
        let resolved = wrappedValue.map { resolvable in
            return resolvable.resolve(for: request)
        }
        
        return EventLoopFuture.whenAllSucceed(
            resolved,
            on: request.eventLoop
        ).map { resolved in
            self.resolved = resolved.compactMap { $0 }
        }
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try C(from: decoder)
        self._resolved = .init(nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        if let resolved = resolved {
            try resolved.encode(to: encoder)
        } else {
            try wrappedValue.encode(to: encoder)
        }
    }
}

@propertyWrapper
public struct PreResolved<PR: PreResolvable & Codable>: Codable, PreEncodable {
    public var wrappedValue: PR
    @ReferenceContaner private var resolved: PR.Resolved?
    
    public init(_ value: PR) {
        self.wrappedValue = value
        self._resolved = .init(nil)
    }
    
    public func shouldPreEncode(for request: Request) -> Bool {
        PR.shouldResolve(for: request, multiple: false)
    }
    
    public func preEncode(for request: Request) -> EventLoopFuture<Void> {
        return wrappedValue.resolve(for: request).map { resolved in
            self.resolved = resolved
        }
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try PR(from: decoder)
        self._resolved = .init(nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        if let resolved = resolved {
            try resolved.encode(to: encoder)
        } else {
            try wrappedValue.encode(to: encoder)
        }
    }
}
