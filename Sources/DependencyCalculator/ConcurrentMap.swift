//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

final class ThreadSafe<A> {
    private var _value: A
    private let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        return queue.sync { _value }
    }
    
    func atomically(_ transform: (inout A) -> ()) {
        queue.sync {
            transform(&self._value)
        }
    }
}

extension Array {
    func concurrentMap<B>(_ transform: @escaping (Element) -> B) -> [B] {
        let result = ThreadSafe(Array<B?>(repeating: nil, count: count))
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
