# AMKit

AMKit aims to improve the lives of Vapor developers by introducing new subjective features:
- Pre-Encodables
  - Reference Resolvers
- Security Rule property wrappers
- Strict Routing

## Pre-Encodables

Pre-Encodables are types that contain a `preEncode` function. 
This is a function that executes when a response is encoded, and takes a request for input.

### Pre-Resolvables

The above functionality is used to implement a pre-encode reference resolver. 
This functionality can resolve, for example, a reference that conforms to PreResolvable.

Below is an integration with [the MongoKitten ORM, Meow](https://github.com/OpenKitten/MongoKitten).

```swift
import AMKit
import Meow
import Vapor

public protocol PreResolvableReadableModel: ReadableModel, Encodable {
    static var preresolveKey: String { get }
    
    func isReadAccessible(for request: Request) -> Bool
}

public typealias PreResolvableModel = PreResolvableReadableModel & MutableModel

extension Reference: PreResolvable where M: PreResolvableReadableModel {
    public func resolve(for request: Request) -> EventLoopFuture<M?> {
        self.resolve(in: request.db).map { entity in
            guard entity.isReadAccessible(for: request) else {
                return nil
            }
            
            return entity
        }
    }
    
    public static func shouldResolve(for request: Request, multiple: Bool) -> Bool {
        guard let preResolveKeys = try? request.query.get(String.self, at: "preresolve") else {
            return false
        }
        
        guard preResolveKeys.split(separator: ",").map(String.init).contains(M.preresolveKey) else {
            return false
        }
        
        return true
    }
}
```

## Security Rules

## Strict Routing

The `SecRouter` adds a new way of defining routes. The method of definition used the Vapor types, but can create routes more cleanly separated from the Application type, and doesn't require passing around a RouteBuilder.

The implementation uses _function builders_, a Swift feature which does not have a stable API yet. Until Function Builders and Vapor 4 are stable, AMKit will not be tagged stable using the current structure. We will likely split off the SecRouterBuilder into another module.

**The SecRouterBuilder, currently, only supports eight routes per block. We'll increase this if we get a complaint.**

Currently, it's kept because it increases our the readability of routes. We work around this by improving the groups of routes.

```swift
func addRoutes(to app: Application) throws {
    // Registers the routes to Application
    // You can capture the `RouteList` using a custom FunctionBuilder
    app.secRoutes {
        APIDocsRoutes()
        AllAnonymousRoutes()
        AuthenticatedRoutes()
    }
}

private func AuthenticatedRoutes() -> some RouteList {
    MiddlewareGroup(AuthenticationMiddleware()) {
        AllUserRoutes()
        AllOrganisationRoutes()
    }
}

private func AllOrganisationRoutes() -> some RouteList {
    PathGroup("organisations", .parameter("organisation", Reference<Organisation>.self)) {
        MiddlewareGroup(OrganisationMiddleware()) {
            GET(run: OrganisationRoutes.getOrganisation)
            
            AllEmployeeRoutes()
            AllOrganisationAdminRoutes()
        }
    }
}
```

### Security Rules

SecRouterBuilder also strongly encourages setting up security rules and security contexts. Both of which help prevent the leaking of data, and applying business logic. It also aims to encourge implementing security rules in isolated files which can be tested.

We encourage creating a custom protocol which improves quality of life when conforming.

```swift
public protocol AMContent: PreEncodedSecuredContent, EncodableExample where SecurityContext == AMSecurityContext {}

extension AMContent {
    public static var securityContentKey: CodingUserInfoKey { ... }
}

public struct AMSecurityContext: SecuredResponseEncodingContext {
    let authenticatedUser: Reference<User>
    
    public init(from request: Request) throws {
        self.authenticatedUser = request.token.user
    }
}

public protocol AMSecurityRule: SecurityRule where UserInfoContext == CISSecurityContext {}
```

By implementing AMSecurityContext on every SecuredContent type, in combination with the router, the context is always used to call `canEncode` and `validate` when using an `AMSecurityRule` implementation.

If it does not get called, this indicates that the content was not encoded using JSON. SecRouterBuilder uses JSON at all times, therefore the codable process was done through the database or some other form of communication.

### Database-Only Encoding

Using the above knowledge, one can implement a security rule that prevents encoding the data to the public API.

```swift
public enum DatabaseOnlyRule<T: Codable>: AMSecurityRule {
    public typealias SecuredProperty = T
    
    public static func canEncode(
        _ value: T,
        subject: Any,
        inContext context: CISSecurityContext?
    ) -> Bool {
        return context == nil
    }
    
    public static func validate(_ value: T) -> Bool {
        return true
    }
}

public typealias DatabaseOnly<T: Codable> = Secured<DatabaseOnlyRule<T>>
```

You can then apply this rule using the following code:

```swift
struct User: Content {
  let email: String
  @DatabaseOnly var password: String
}
```

### Security Rule Subject

The subject in the above example was an `Any` type. This means that you don't care for the subject that is being encoded. The subject is the top-level entity that is encoded and returned from the route. In the case of an `EventLoopFuture`, the subject is the wrapped entity.

You can restrict `canEncode` to encode only for a specific subject. The following code, for example, only encodes if the subject is a User model. This works for protocols as well.

```swift
public enum UserPropertyOnlyRule<T: Codable>: AMSecurityRule {
    public typealias SecuredProperty = T
    
    public static func canEncode(
        _ value: T,
        subject: User,
        inContext context: CISSecurityContext?
    ) -> Bool {
        return true
    }
    
    public static func validate(_ value: T) -> Bool {
        return true
    }
}

public typealias UserPropertyOnly<T: Codable> = Secured<UserPropertyOnlyRule<T>>
```

A good use case is to check permissions before you encode said entity to the user. The above example discards knowledge of the security context, and merely checks that a User (conforming) instance is being encoded. You can implement business rules here any way you see fit.

### Ideas

SecurityRules can become a powerful tool in combination with Pre-Encoded properties! By combining the pre-encode process with a database lookup, one can check permissions before returning them over the API. Be wary for performance, though.
