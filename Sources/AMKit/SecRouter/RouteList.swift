import Vapor

public struct Routes: RouteList {
    public let routes: [Route]
    
    public init(routes: [Route]) {
        self.routes = routes
    }
    
    public init(@SecRouteBuilder build: () -> RouteList) {
        self.routes = build().routes
    }
}

public protocol RouteList {
    var routes: [Route] { get }
}

extension Route: RouteList {
    public var routes: [Route] { [self] }
}
