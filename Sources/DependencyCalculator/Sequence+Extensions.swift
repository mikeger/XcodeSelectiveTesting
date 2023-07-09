//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

extension Sequence {
    func toDictionary<ValueType>(path: KeyPath<Iterator.Element, ValueType>) -> [ValueType: Iterator.Element] {
        var result: [ValueType: Iterator.Element] = [:]
        
        forEach { element in
            result[element[keyPath: path]] = element
        }
        
        return result
    }
}
