import Vapor

extension Storage {
    private struct _Key<Value>: StorageKey {}
    
    public mutating func singleton<T>(_ type: T.Type = T.self, factory: () -> T) -> T {
        if let instance = self[_Key<T>.self] {
            return instance
        }
        
        let instance = factory()
        self[_Key<T>.self] = instance
        return instance
    }
}

extension Application {
    public var routeDescription: RouteDescription {
        storage.singleton(factory: RouteDescription.init)
    }
    
    public func secRoutes(@SecRouteBuilder build: () -> RouteList) {
        let description = self.routeDescription

        for route in build().routes {
            description.describeRoute(route)
            self.add(route)
        }
    }
}
