public protocol SecurityRule {
    associatedtype UserInfoContext
    associatedtype EncoderSubject = Any
    associatedtype SecuredProperty: Codable
    
    static var contextUserInfoKey: CodingUserInfoKey { get }
    
    static func validate(_ value: SecuredProperty) -> Bool
    static func canEncode(
        _ value: SecuredProperty,
        subject: EncoderSubject,
        inContext context: UserInfoContext?
    ) -> Bool
}
