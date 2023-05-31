//
//  Array+Extensions.swift
//  
//
//  Created by Atakan Karslı on 27/02/2023.
//

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
}
