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
