import Vapor

public enum RichPathComponent: ExpressibleByStringLiteral, CustomStringConvertible {
    case constant(String)
    case parameter(String, DescribedParameter.Type)
    case anything
    case catchall

    public init(stringLiteral value: String) {
        self = .constant(value)
    }

    var pathComponent: PathComponent {
        switch self {
        case .anything:
            return .anything
        case .catchall:
            return .catchall
        case .constant(let constant):
            return .constant(constant)
        case .parameter(let parameter, _):
            return .parameter(parameter)
        }
    }

    public var description: String {
        pathComponent.description
    }
}
