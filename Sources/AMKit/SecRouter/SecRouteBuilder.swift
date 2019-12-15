import Vapor

@_functionBuilder
public struct SecRouteBuilder {
    public static func buildBlock() -> Routes {
        Routes(routes: [])
    }

    public static func buildBlock<R0: RouteList>(_ routes: R0) -> RouteList {
        routes
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList
    >(
        _ r0: R0, _ r1: R1
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList
    >(
        _ r0: R0, _ r1: R1, _ r2: R2
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList, R3: RouteList
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        routes += r3.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList, R3: RouteList,
        R4: RouteList
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        routes += r3.routes
        routes += r4.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList, R3: RouteList,
        R4: RouteList, R5: RouteList
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        routes += r3.routes
        routes += r4.routes
        routes += r5.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList, R3: RouteList,
        R4: RouteList, R5: RouteList, R6: RouteList
    >(
    _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        routes += r3.routes
        routes += r4.routes
        routes += r5.routes
        routes += r6.routes
        return Routes(routes: routes)
    }

    public static func buildBlock<
        R0: RouteList, R1: RouteList, R2: RouteList, R3: RouteList,
        R4: RouteList, R5: RouteList, R6: RouteList, R7: RouteList
    >(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7
    ) -> RouteList {
        var routes = [Route]()
        routes += r0.routes
        routes += r1.routes
        routes += r2.routes
        routes += r3.routes
        routes += r4.routes
        routes += r5.routes
        routes += r6.routes
        routes += r7.routes
        return Routes(routes: routes)
    }
}
