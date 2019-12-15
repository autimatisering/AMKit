internal enum SecurityRuleError<Rule: SecurityRule>: Error {
    case validationFailed(value: Rule.SecuredProperty, rule: Rule.Type)
}
