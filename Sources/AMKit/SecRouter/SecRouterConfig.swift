import Vapor
import IkigaJSON

struct SecRouterConfigKey: StorageKey {
    public typealias Value = SecRouterConfig
}

public protocol SecRouterConfig {
    var developmentMode: Bool { get }
    var preEncodeResponses: Bool { get }
    var jsonErrorDecodingSettings: JSONDecoderSettings { get }
    
    func makeJSONDecodingErrorResponse(report: JSONErrorReport) -> Error
}

extension SecRouterConfig {
    public var jsonErrorDecodingSettings: JSONDecoderSettings {
        var settings = JSONDecoderSettings()
        settings.dateDecodingStrategy = .iso8601
        return settings
    }
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
