//
//  RangeReplaceableCollection+Merge.swift
//  WorkoutSpot
//
//  Created by Leptos on 6/15/23.
//  Copyright © 2023 Leptos. All rights reserved.
//

import Foundation

extension RangeReplaceableCollection {
    static func sortedMerge<LS: Sequence, RS: Sequence, SC: SortComparator>(_ lhs: LS, _ rhs: RS, using sortComparator: SC) -> Self
    where LS.Element == Element, RS.Element == Element, SC.Compared == Element {
        var lhsIterator = lhs.makeIterator()
        var rhsIterator = rhs.makeIterator()
        
        var build: Self = .init()
        
        var lhsUp = lhsIterator.next()
        var rhsUp = rhsIterator.next()
        
        while lhsUp != nil || rhsUp != nil {
            if let lhsCheck = lhsUp, let rhsCheck = rhsUp {
                if sortComparator.compare(lhsCheck, rhsCheck) == .orderedAscending {
                    build.append(lhsCheck)
                    lhsUp = lhsIterator.next()
                    
                    assert(lhsUp.map { sortComparator.compare(lhsCheck, $0) == .orderedAscending } ?? true, "lhs is not sorted by sortComparator")
                } else {
                    build.append(rhsCheck)
                    rhsUp = rhsIterator.next()
                    
                    assert(rhsUp.map { sortComparator.compare(rhsCheck, $0) == .orderedAscending } ?? true, "rhs is not sorted by sortComparator")
                }
            } else if let lhsCheck = lhsUp {
                build.append(lhsCheck)
                lhsUp = lhsIterator.next()
                
                assert(lhsUp.map { sortComparator.compare(lhsCheck, $0) == .orderedAscending } ?? true, "lhs is not sorted by sortComparator")
            } else if let rhsCheck = rhsUp {
                build.append(rhsCheck)
                rhsUp = rhsIterator.next()
                
                assert(rhsUp.map { sortComparator.compare(rhsCheck, $0) == .orderedAscending } ?? true, "rhs is not sorted by sortComparator")
            } else {
                fatalError("All values are nil")
            }
        }
        
        return build
    }
}
