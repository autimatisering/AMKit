import Vapor

struct SecRouterConfigKey: StorageKey {
    public typealias Value = SecRouterConfig
}

public protocol SecRouterConfig {
    var developmentMode: Bool { get }
    
    func makeJSONDecodingErrorResponse(report: JSONErrorReport) -> Error
}

extension Application {
    public var secRouterConfig: SecRouterConfig? {
        get {
            storage.get(SecRouterConfigKey.self)
        }
        set {
            storage.set(SecRouterConfigKey.self, to: newValue)
        }
    }
}
