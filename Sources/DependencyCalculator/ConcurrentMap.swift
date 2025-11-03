//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

final class ThreadSafe<A: Sendable>: @unchecked Sendable {
    private var _value: A
    private let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) {
        _value = value
    }

    var value: A {
        return queue.sync { _value }
    }

    func atomically(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&self._value)
        }
    }
}

extension Array where Element: Sendable {
    func concurrentMap<B: Sendable>(_ transform: @escaping @Sendable (Element) -> B) -> [B] {
        let result = ThreadSafe([B?](repeating: nil, count: count))
        DispatchQueue.concurrentPerform(iterations: count) { idx in
            let element = self[idx]
            let transformed = transform(element)
            result.atomically {
                $0[idx] = transformed
            }
        }
        return result.value.map { $0! }
    }
}
