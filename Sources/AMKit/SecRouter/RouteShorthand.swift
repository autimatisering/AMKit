import Vapor
import IkigaJSON

fileprivate extension Request {
    func decodeReportingErrors<Input: Decodable>(_ input: Input.Type) throws -> Input {
        do {
            return try content.decode(input)
        } catch {
            guard
                let config = application.secRouterConfig,
                config.developmentMode,
                let buffer = body.data
            else {
                throw error
            }
            
            let object = try JSONObject(buffer: buffer)
            let report = decodingErrors(for: Input.self, from: object, settings: config.jsonErrorDecodingSettings)
            throw config.makeJSONDecodingErrorResponse(report: report)
        }
    }
}

public func GET<SRE: SecuredResponseEncodable>(
    _ path: RichPathComponent...,
    run: @escaping (Request) throws -> SRE
) -> Route {
    GET(path, run: run)
}

public func GET<SRE: SecuredResponseEncodable>(
    _ path: [RichPathComponent] = [],
    run: @escaping (Request) throws -> SRE
) -> Route {
    Route(method: .GET, path: path, input: Never.self, route: run)
}

public func PATCH<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: RichPathComponent...,
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    PATCH(path, input: input, run: run)
}

public func PATCH<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: [RichPathComponent] = [],
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    Route(
        method: .PATCH,
        path: path,
        input: Input.self
    ) { request -> SRE in
        let input = try request.decodeReportingErrors(Input.self)
        return try run(request, input)
    }
}

public func PUT<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: RichPathComponent...,
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    PUT(path, input: input, run: run)
}

public func PUT<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: [RichPathComponent] = [],
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    Route(
        method: .PUT,
        path: path,
        input: Input.self
    ) { request -> SRE in
        let input = try request.decodeReportingErrors(Input.self)
        return try run(request, input)
    }
}

public func POST<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: RichPathComponent...,
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    POST(path, input: input, run: run)
}

public func POST<SRE: SecuredResponseEncodable, Input: DescribedRequest & Content>(
    _ path: [RichPathComponent] = [],
    input: Input.Type = Input.self,
    run: @escaping (Request, Input) throws -> SRE
) -> Route {
    Route(
        method: .POST,
        path: path,
        input: Input.self
    ) { request -> SRE in
        let input = try request.decodeReportingErrors(Input.self)
        return try run(request, input)
    }
}

public func POST<SRE: SecuredResponseEncodable>(
    _ path: [RichPathComponent] = [],
    input: Never.Type = Never.self,
    run: @escaping (Request) throws -> SRE
) -> Route {
    Route(
        method: .POST,
        path: path,
        input: input,
        route: run
    )
}
