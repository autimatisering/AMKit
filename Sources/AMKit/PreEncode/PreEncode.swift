import Vapor

public protocol PreEncodable: Encodable {
    func shouldPreEncode(for request: Request) -> Bool
    func preEncode(for request: Request) -> EventLoopFuture<Void>
}

public func preEncode<E: Encodable>(_ entity: E, for request: Request) -> EventLoopFuture<Void> {
    do {
        let encoder = PreEncoder()
        try entity.encode(to: encoder)
        var resolveEvents = [EventLoopFuture<Void>]()
        
        if let entity = entity as? PreEncodable, entity.shouldPreEncode(for: request) {
            resolveEvents.append(entity.preEncode(for: request))
        }
        
        for preEncodable in encoder.preEncodables where preEncodable.shouldPreEncode(for: request) {
            resolveEvents.append(preEncodable.preEncode(for: request))
        }

        return EventLoopFuture.andAllSucceed(resolveEvents, on: request.eventLoop)
    } catch {
        return request.eventLoop.future(error: error)
    }
}

fileprivate final class PreEncoder: Encoder {
    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey : Any] { [:] }
    var preEncodables = [PreEncodable]()
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        KeyedEncodingContainer(KeyedPreEncodingContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        BasicPreEncodingContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        BasicPreEncodingContainer(encoder: self)
    }
}

fileprivate struct KeyedPreEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: PreEncoder
    var codingPath: [CodingKey] { [] }
    
    mutating func encodeNil(forKey key: Key) throws {}
    mutating func encode(_ value: Bool, forKey key: Key) throws {}
    mutating func encode(_ value: String, forKey key: Key) throws {}
    mutating func encode(_ value: Double, forKey key: Key) throws {}
    mutating func encode(_ value: Float, forKey key: Key) throws {}
    mutating func encode(_ value: Int, forKey key: Key) throws {}
    mutating func encode(_ value: Int8, forKey key: Key) throws {}
    mutating func encode(_ value: Int16, forKey key: Key) throws {}
    mutating func encode(_ value: Int32, forKey key: Key) throws {}
    mutating func encode(_ value: Int64, forKey key: Key) throws {}
    mutating func encode(_ value: UInt, forKey key: Key) throws {}
    mutating func encode(_ value: UInt8, forKey key: Key) throws {}
    mutating func encode(_ value: UInt16, forKey key: Key) throws {}
    mutating func encode(_ value: UInt32, forKey key: Key) throws {}
    mutating func encode(_ value: UInt64, forKey key: Key) throws {}
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        if let value = value as? PreEncodable {
            encoder.preEncodables.append(value)
        }
        
        try value.encode(to: encoder)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        KeyedEncodingContainer(KeyedPreEncodingContainer<NestedKey>(encoder: encoder))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        BasicPreEncodingContainer(encoder: encoder)
    }
    
    mutating func superEncoder() -> Encoder {
        encoder
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        encoder
    }
}

fileprivate struct BasicPreEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
    mutating func encode(_ value: String) throws {}
    mutating func encode(_ value: Double) throws {}
    mutating func encode(_ value: Float) throws {}
    mutating func encode(_ value: Int) throws {}
    mutating func encode(_ value: Int8) throws {}
    mutating func encode(_ value: Int16) throws {}
    mutating func encode(_ value: Int32) throws {}
    mutating func encode(_ value: Int64) throws {}
    mutating func encode(_ value: UInt) throws {}
    mutating func encode(_ value: UInt8) throws {}
    mutating func encode(_ value: UInt16) throws {}
    mutating func encode(_ value: UInt32) throws {}
    mutating func encode(_ value: UInt64) throws {}
    mutating func encodeNil() throws {}
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let value = value as? PreEncodable {
            encoder.preEncodables.append(value)
        }
        
        try value.encode(to: encoder)
    }
    
    mutating func encode(_ value: Bool) throws {}
    
    let encoder: PreEncoder
    var codingPath: [CodingKey] { [] }
    var count: Int = 0
    
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        KeyedEncodingContainer(KeyedPreEncodingContainer<NestedKey>(encoder: encoder))
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self
    }
    
    mutating func superEncoder() -> Encoder {
        encoder
    }
}
