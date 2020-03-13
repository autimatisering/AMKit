@propertyWrapper
public struct Secured<Rule: SecurityRule> {
    public var wrappedValue: Rule.SecuredProperty
    
    public init(_ value: Rule.SecuredProperty) {
        self.wrappedValue = value
    }
}

extension Secured: Encodable where Rule.SecuredProperty: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        guard
            let context = encoder.userInfo[Rule.contextUserInfoKey] as? Rule.UserInfoContext
        else {
            try container.encode(wrappedValue)
            return
        }
        
        guard
            let subject = encoder.userInfo[SecurityHelper.subjectKey] as? Rule.EncoderSubject,
            Rule.canEncode(wrappedValue, subject: subject, inContext: context)
        else {
            try container.encodeNil()
            return
        }
        
        try container.encode(wrappedValue)
    }
}

extension Secured: Decodable where Rule.SecuredProperty: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Rule.SecuredProperty.self)
        
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
