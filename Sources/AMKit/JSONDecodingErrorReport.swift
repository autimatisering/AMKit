import Foundation
import IkigaJSON

internal enum JSONInspectedValue {
    case object(JSONObject)
    case array(JSONArray)
    case single(JSONValue?)
    
    var jsonType: JSONTypeExpectation {
        switch self {
        case .array, .single(is JSONArray):
            return .array
        case .object, .single(is JSONObject):
            return .object
        case .single(is NSNull):
            return .null
        case .single(is String):
            return .string
        case .single(is Double):
            return .number
        case .single(is Int):
            return .number
        case .single(is Bool):
            return .bool
        default:
            return .none
        }
    }
}

extension JSONValue {
    var jsonType: JSONTypeExpectation {
        switch self {
        case is JSONArray:
            return .array
        case is JSONObject:
            return .object
        case is NSNull:
            return .null
        case is String:
            return .string
        case is Double:
            return .number
        case is Int:
            return .number
        case is Bool:
            return .bool
        default:
            return .none
        }
    }
}

internal enum _CodingKey: CodingKey {
    case int(Int)
    case string(String)
    
    init(intValue: Int) {
        self = .int(intValue)
    }
    
    init(stringValue: String) {
        self = .string(stringValue)
    }
    
    var intValue: Int? {
        if case .int(let int) = self {
            return int
        }
        
        return nil
    }
    
    var stringValue: String {
        switch self {
        case .int(let int):
            return String(int)
        case .string(let string):
            return string
        }
    }
}

public enum JSONTypeExpectation {
    case object, array, string, number, null, none, bool
}

public func decodingErrors<D: Decodable>(for entity: D.Type, from object: JSONObject, settings: JSONDecoderSettings = .init()) -> JSONErrorReport {
    let container = ErrorContainer(stopOnErrors: true)
    
    do {
        let decoder = JSONObjectInspectorDecoder(
            codingPath: [],
            userInfo: [:],
            value: .object(object),
            settings: settings,
            container: container
        )
        _ = try D(from: decoder)
    } catch {}
    
    return container.errorReport
}

public enum JSONInspectorError: Error {
    case invalidValue(path: [CodingKey], found: JSONTypeExpectation, needed: JSONTypeExpectation, type: Any.Type)
    case invalidInteger(path: [CodingKey], found: Int, needed: Any.Type)
}

public struct CodingKeyPath: Hashable {
    public static func == (lhs: CodingKeyPath, rhs: CodingKeyPath) -> Bool {
        lhs.keys.map { $0.stringValue } == rhs.keys.map { $0.stringValue }
    }
    
    public func hash(into hasher: inout Hasher) {
        for key in keys {
            key.stringValue.hash(into: &hasher)
        }
    }
    
    public let keys: [CodingKey]
}

public struct JSONErrorReport {
    public let errors: [JSONInspectorError]
    public let unusedKeys: [CodingKeyPath: Set<String>]
}

internal final class ErrorContainer {
    var errors: [JSONInspectorError]
    var unusedKeys: [CodingKeyPath: Set<String>]
    let stopOnErrors: Bool
    
    var errorReport: JSONErrorReport {
        JSONErrorReport(
            errors: errors,
            unusedKeys: unusedKeys
        )
    }
    
    init(stopOnErrors: Bool) {
        self.errors = []
        self.unusedKeys = [:]
        self.stopOnErrors = stopOnErrors
    }
    
    func error(_ error: JSONInspectorError) -> JSONInspectorError {
        self.errors.append(error)
        return error
    }
}

protocol JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { get }
}

extension String: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .string }
}
extension Bool: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .bool }
}
extension Double: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .number }
}
extension NSNull: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .null }
}
extension JSONArray: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .array }
}
extension JSONObject: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .object }
}
extension Float: JSONTypeRepresentable {
    static var jsonType: JSONTypeExpectation { .number }
}

internal struct JSONObjectInspectorDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo = [CodingUserInfoKey : Any]()
    let value: JSONInspectedValue
    var settings: JSONDecoderSettings
    let container: ErrorContainer
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        switch value {
        case .object(let object), .single(let object as JSONObject):
            let container = JSONKeyedValueDecodingContainer<Key>(value: object, decoder: self)
            return KeyedDecodingContainer(container)
        default:
            throw container.error(.invalidValue(path: codingPath, found: value.jsonType, needed: .object, type: JSONObject.self))
        }
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        JSONSingleValueDecodingContainer(value: value, decoder: self)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch value {
        case .array(let array), .single(let array as JSONArray):
            return JSONUnkeyedValueDecodingContainer(value: array, decoder: self)
        default:
            throw container.error(.invalidValue(path: codingPath, found: value.jsonType, needed: .array, type: JSONArray.self))
        }
    }
}

struct JSONKeyedValueDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] { decoder.codingPath}
    let value: JSONObject
    let decoder: JSONObjectInspectorDecoder
    var container: ErrorContainer { decoder.container }
    var allKeys: [Key] {
        value.keys.compactMap(Key.init)
    }
    
    init(value: JSONObject, decoder: JSONObjectInspectorDecoder) {
        self.value = value
        self.decoder = decoder
        
        var unusedKeys = Set<String>()
        for key in value.keys {
            if Key(stringValue: key) == nil {
                unusedKeys.insert(key)
            }
        }
        
        if !unusedKeys.isEmpty {
            let path = CodingKeyPath(keys: codingPath)
            container.unusedKeys[path] = unusedKeys
        }
    }
    
    func contains(_ key: Key) -> Bool {
        value.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        if contains(key) {
            return value[key.stringValue] is NSNull
        }
        
        return true
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try unwrapSingle(for: key)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try unwrapSingle(for: key)
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath,
            userInfo: self.decoder.userInfo,
            value: .single(value[key.stringValue]),
            settings: self.decoder.settings,
            container: container
        )
        let container = try decoder.singleValueContainer()
        return try container.decode(T.self)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let nextValue = value[key.stringValue]
        guard let value = nextValue as? JSONObject else {
            throw container.error(.invalidValue(path: codingPath + [key], found: nextValue?.jsonType ?? .none, needed: .object, type: JSONObject.self))
        }
        
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            value: .object(value),
            settings: self.decoder.settings,
            container: container
        )
        return try decoder.container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let nextValue = value[key.stringValue]
        guard let value = nextValue as? JSONArray else {
            throw container.error(.invalidValue(path: codingPath + [key], found: nextValue?.jsonType ?? .none, needed: .array, type: JSONArray.self))
        }
        
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath + [key],
            userInfo: self.decoder.userInfo,
            value: .array(value),
            settings: self.decoder.settings,
            container: container
        )
        return try decoder.unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        decoder
    }
    
    func unwrapSingle<T: FixedWidthInteger>(for key: Key) throws -> T {
        let nextValue = value[key.stringValue]
        guard let value = nextValue as? Int else {
            throw container.error(.invalidValue(path: codingPath + [key], found: nextValue?.jsonType ?? .none, needed: .number, type: T.self))
        }
        
        guard let int = T(exactly: value) else {
            throw container.error(.invalidInteger(path: codingPath + [key], found: value, needed: T.self))
        }
        
        return int
    }
    
    func unwrapSingle<T: JSONTypeRepresentable>(for key: Key) throws -> T {
        let nextValue = value[key.stringValue]
        guard let value = nextValue as? T else {
            throw container.error(
                .invalidValue(
                    path: codingPath + [key],
                    found: nextValue?.jsonType ?? .none,
                    needed: T.jsonType,
                    type: T.self
                )
            )
        }
        
        return value
    }
}

struct JSONSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] { decoder.codingPath}
    let value: JSONInspectedValue
    let decoder: JSONObjectInspectorDecoder
    var container: ErrorContainer { decoder.container }
    
    func decodeNil() -> Bool {
        guard case let .single(primitive) = value else {
            return false
        }
        
        if let primitive = primitive {
            return primitive is NSNull
        }
        
        return true
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try unwrapSingle()
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try unwrapSingle()
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try unwrapSingle()
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try unwrapSingle()
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try unwrapSingle()
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try unwrapSingle()
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try unwrapSingle()
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try unwrapSingle()
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try unwrapSingle()
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try unwrapSingle()
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try unwrapSingle()
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try unwrapSingle()
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try unwrapSingle()
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if T.self is Date.Type {
            switch self.decoder.settings.dateDecodingStrategy {
            case .iso8601:
                guard
                    case .single(let string as String) = value,
                    let date = ISO8601DateFormatter().date(from: string)
                else {
                    throw container.error(.invalidValue(path: codingPath, found: value.jsonType, needed: .string, type: type))
                }
                
                return date as! T
            case .formatted(let formatter):
                guard
                case .single(let string as String) = value,
                    let date = formatter.date(from: string)
                else {
                    throw container.error(.invalidValue(path: codingPath, found: value.jsonType, needed: .string, type: type))
                }
                
                return date as! T
            case .secondsSince1970, .millisecondsSince1970:
                if case .single(let double as Double) = value {
                    return Date(timeIntervalSince1970: double) as! T
                } else if case .single(let int as Int) = value {
                    return Date(timeIntervalSince1970: Double(int)) as! T
                } else {
                    throw container.error(.invalidValue(path: codingPath, found: value.jsonType, needed: .number, type: type))
                }
            case .custom(let decode):
                let decoder = JSONObjectInspectorDecoder(
                    codingPath: codingPath,
                    userInfo: self.decoder.userInfo,
                    value: value,
                    settings: self.decoder.settings,
                    container: container
                )
                return try decode(decoder) as! T
            case .deferredToDate:
                fallthrough
            @unknown default:
                let decoder = JSONObjectInspectorDecoder(
                    codingPath: codingPath,
                    userInfo: self.decoder.userInfo,
                    value: value,
                    settings: self.decoder.settings,
                    container: container
                )
                
                return try T(from: decoder)
            }
        } else {
            let decoder = JSONObjectInspectorDecoder(
                codingPath: codingPath,
                userInfo: self.decoder.userInfo,
                value: value,
                settings: self.decoder.settings,
                container: container
            )
            return try T(from: decoder)
        }
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try unwrapSingle()
    }
    
    func unwrapSingle<T: FixedWidthInteger>() throws -> T {
        guard case let .single(value as Int) = value else {
            throw container.error(
                .invalidValue(
                    path: codingPath,
                    found: self.value.jsonType,
                    needed: .number,
                    type: T.self
                )
            )
        }
        
        guard let int = T(exactly: value) else {
            throw container.error(.invalidInteger(path: codingPath, found: value, needed: T.self))
        }
        
        return int
    }
    
    func unwrapSingle<T: JSONTypeRepresentable>() throws -> T {
        guard case let .single(value as T) = value else {
            throw container.error(
                .invalidValue(
                    path: codingPath,
                    found: self.value.jsonType,
                    needed: T.jsonType,
                    type: T.self
                )
            )
        }
        
        return value
    }
}

struct JSONUnkeyedValueDecodingContainer: UnkeyedDecodingContainer {
    var currentIndex = 0
    var codingPath: [CodingKey] { decoder.codingPath}
    let value: JSONArray
    let decoder: JSONObjectInspectorDecoder
    var container: ErrorContainer { decoder.container }
    
    var count: Int? {
        value.count
    }
    var isAtEnd: Bool {
        currentIndex >= value.count
    }
    
    var nextValue: JSONValue? {
        mutating get {
            let nextValue = value[currentIndex]
            currentIndex += 1
            return nextValue
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let index = currentIndex
        let nextValue = self.nextValue
        guard let object = nextValue as? JSONObject else {
            throw container.error(.invalidValue(path: codingPath, found: nextValue?.jsonType ?? .none, needed: .array, type: JSONArray.self))
        }
        
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath + [_CodingKey.init(intValue: index)],
            userInfo: self.decoder.userInfo,
            value: .object(object),
            settings: self.decoder.settings,
            container: container
        )
        return try decoder.container(keyedBy: type)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let index = currentIndex
        let nextValue = self.nextValue
        guard let array = nextValue as? JSONArray else {
            throw container.error(.invalidValue(path: codingPath, found: nextValue?.jsonType ?? .none, needed: .array, type: JSONArray.self))
        }
        
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath + [_CodingKey.init(intValue: index)],
            userInfo: self.decoder.userInfo,
            value: .array(array),
            settings: self.decoder.settings,
            container: container
        )
        return try decoder.unkeyedContainer()
    }
    
    mutating func superDecoder() throws -> Decoder {
        decoder
    }
    
    mutating func decodeNil() -> Bool {
        guard let primitive = nextValue else {
            return false
        }
        
        return primitive is NSNull
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try unwrapSingle()
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try unwrapSingle()
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let decoder = JSONObjectInspectorDecoder(
            codingPath: codingPath,
            userInfo: self.decoder.userInfo,
            value: .single(self.nextValue),
            settings: self.decoder.settings,
            container: container
        )
        return try decoder.singleValueContainer().decode(type)
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        return try unwrapSingle()
    }
    
    mutating func unwrapSingle<T: FixedWidthInteger>() throws -> T {
        let nextValue = self.nextValue
        guard let value = nextValue as? Int else {
            throw container.error(.invalidValue(path: codingPath, found: nextValue?.jsonType ?? .none, needed: .number, type: T.self))
        }
        
        guard let int = T(exactly: value) else {
            throw container.error(.invalidInteger(path: codingPath, found: value, needed: T.self))
        }
        
        return int
    }
    
    mutating func unwrapSingle<T: JSONTypeRepresentable>() throws -> T {
        let nextValue = self.nextValue
        guard let value = nextValue as? T else {
            throw container.error(
                .invalidValue(
                    path: codingPath,
                    found: nextValue?.jsonType ?? .none,
                    needed: T.jsonType,
                    type: T.self
                )
            )
        }
        
        return value
    }
}
