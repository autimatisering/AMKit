public struct SecurityHelper {
    public static let subjectKey = CodingUserInfoKey(rawValue: "security-helper-subject-key")!
    
    public static func updateContext<T>(in userInfo: inout [CodingUserInfoKey: Any], forSubject subject: T) {
        userInfo[SecurityHelper.subjectKey] = subject
    }
}
