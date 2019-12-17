@propertyWrapper
public struct Secured<Rule: SecurityRule> {
    public var wrappedValue: Rule.SecuredProperty
    
    public init(_ value: Rule.SecuredProperty) {
        self.wrappedValue = value
    }
}

extension Secured: Encodable where Rule.SecuredProperty: Encodable {
    public func encode(to encoder: Encoder) throws {
        guard
            let context = encoder.userInfo[Rule.contextUserInfoKey] as? Rule.UserInfoContext
        else {
            try wrappedValue.encode(to: encoder)
        }
        
        guard
            let subject = encoder.userInfo[SecurityHelper.subjectKey] as? Rule.EncoderSubject,
            Rule.canEncode(wrappedValue, subject: subject, inContext: context)
        else {
            return
        }
        
        try wrappedValue.encode(to: encoder)
    }
}

extension Secured: Decodable where Rule.SecuredProperty: Decodable {
    public init(from decoder: Decoder) throws {
        wrappedValue = try Rule.SecuredProperty(from: decoder)
        
        guard Rule.validate(wrappedValue) else {
            throw SecurityRuleError<Rule>.validationFailed(value: wrappedValue, rule: Rule.self)
        }
    }
}

extension Secured: ExpressibleByNilLiteral where Rule.SecuredProperty: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = Secured<Rule>(Rule.SecuredProperty(nilLiteral: ()))
    }
}
