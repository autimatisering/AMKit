import Vapor
import IkigaJSON

extension Route {
    public convenience init<SRE: SecuredResponseEncodable>(
        method: HTTPMethod,
        path: [RichPathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        input: DescribedRequest.Type,
        route: @escaping (Request) throws -> SRE
    ) {
        self.init(
            method: method,
            path: path.map { $0.pathComponent },
            responder: BasicResponder { request in
                if case .collect(let max) = body, request.body.data == nil {
                    return request.body.collect(max: max).flatMapThrowing { _ in
                        return try route(request)
                    }.encodeResponse(for: request)
                } else {
                    return try route(request)
                        .encodeResponse(for: request)
                }
            },
            requestType: input,
            responseType: SRE.self
        )
        
        for component in path {
            if case let .parameter(parameter, type) = component {
                self.parameterTypes[parameter] = type
            }
        }
    }
    
    public var parameterTypes: [String: DescribedParameter.Type] {
        get {
            let instance = userInfo["parameter-types"] as? [String: DescribedParameter.Type]
            return instance ?? [:]
        }
        set {
            userInfo["parameter-types"] = newValue
        }
    }
}
