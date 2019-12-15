import Vapor

public struct MiddlewareGroup: RouteList {
    public let routes: [Route]
    
    public init(_ middlewares: [Middleware], @SecRouteBuilder build: () -> RouteList) {
        func applyingMiddleware(route: Route) -> Route {
            route.responder = middlewares.makeResponder(chainingTo: route.responder)
            return route
        }
        
        self.routes = build().routes.map(applyingMiddleware)
    }
    
    public init(_ middlewares: Middleware..., @SecRouteBuilder build: () -> RouteList) {
        self.init(middlewares, build: build)
    }
}
