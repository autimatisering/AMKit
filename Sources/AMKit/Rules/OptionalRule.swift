public enum OptionalRule<Rule: SecurityRule>: SecurityRule {
    public typealias SecuredProperty = Rule.SecuredProperty?
    public typealias EncoderSubject = Rule.EncoderSubject
    public typealias UserInfoContext = Rule.UserInfoContext
    
    public static var contextUserInfoKey: CodingUserInfoKey {
        Rule.contextUserInfoKey
    }
    
    public static func canEncode(_ value: SecuredProperty, subject: EncoderSubject, inContext context: UserInfoContext?) -> Bool {
        guard let value = value else {
            return true
        }
        
        return Rule.canEncode(value, subject: subject, inContext: context)
    }
    
    public static func validate(_ value: SecuredProperty) -> Bool {
        guard let value = value else {
            return true
        }
        
        return Rule.validate(value)
    }
}
