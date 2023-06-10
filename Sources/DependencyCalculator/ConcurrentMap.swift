//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public final class ThreadSafe<A> {
    var _value: A
    let queue = DispatchQueue(label: "ThreadSafe")
    init(_ value: A) { self._value = value }

    var value: A {
        return queue.sync { _value }
    }
    func atomically(_ transform: (inout A) -> ()) {
        queue.sync { transform(&self._value) }
    }
}

extension RandomAccessCollection {

    func concurrentMap<B>(_ transform: (Element) -> B) -> [B] {
        let batchSize = 4096 // Tune this
        let n = self.count
        let batchCount = (n + batchSize - 1) / batchSize
        if batchCount < 2 { return self.map(transform) }

        let batches = ThreadSafe(
            ContiguousArray<[B]?>(repeating: nil, count: batchCount))

        func batchStart(_ b: Int) -> Index {
            index(startIndex, offsetBy: b * n / batchCount)
        }
        
        DispatchQueue.concurrentPerform(iterations: batchCount) { b in
            let batch = self[batchStart(b)..<batchStart(b + 1)].map(transform)
            batches.atomically { $0[b] = batch }
        }
        
        return batches.value.flatMap { $0! }
    }
}
