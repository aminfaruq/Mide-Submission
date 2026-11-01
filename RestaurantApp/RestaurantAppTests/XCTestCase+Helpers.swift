//
//  XCTestCase+Helpers.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RestaurantCore
import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Should have been deallocated. Potential memory leaks", file: file, line: line)
        }
    }
}

func anyError() -> NSError {
    NSError(domain: "an-error", code: -99999)
}

// MARK: - Entity helpers
func makeRestaurant(
    id: String = UUID().uuidString,
    name: String
) -> RestaurantEntity {
    .init(
        id: id,
        name: name,
        description: "a desc",
        pictureId: "an id",
        city: "any-city",
        rating: 4.5
    )
}
