import Vapor

public struct PathGroup: RouteList {
    public let routes: [Route]
    
    public init(_ path: RichPathComponent, @SecRouteBuilder build: () -> RouteList) {
        self.init([path], build: build)
    }
    
    public init(_ path: [RichPathComponent], @SecRouteBuilder build: () -> RouteList) {
        func applyingPath(route: Route) -> Route {
            let components = path.map { $0.pathComponent }
            route.path.insert(contentsOf: components, at: 0)
            
            for component in path {
                if case let .parameter(parameter, type) = component {
                    route.parameterTypes[parameter] = type
                }
            }
            
            return route
        }
        
        self.routes = build().routes.map(applyingPath)
    }
    
    public init(_ path: RichPathComponent..., @SecRouteBuilder build: () -> RouteList) {
        self.init(path, build: build)
    }
}
