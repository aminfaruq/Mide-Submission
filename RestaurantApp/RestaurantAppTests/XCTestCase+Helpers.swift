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

func anyId() -> String {
    UUID().uuidString
}

// MARK: - Entity helpers
func makeRestaurant(
    id: String = anyId(),
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

func makeDetailRestaurant(
    id: String = anyId(),
    name: String
) -> RestaurantDetailEntity {
    .init(
        id: id,
        name: name,
        description: "a description",
        city: "a city",
        address: "an address",
        pictureId: "a pictureId",
        categories: [
            CategoryEntity(name: "a name")
        ],
        menus: MenuEntity(
            foods: [
                CategoryEntity(name: "a name")
            ],
            drinks: [
                CategoryEntity(name: "a name")
            ]
        ),
        rating: 0.0,
        customerReviews: [
            CustomerReviewEntity(
                name: "a name",
                review: "a review",
                date: "a date"
            )
        ]
    )
}

func makeReview() -> AddReviewBody {
    .init(id: anyId(), name: "a name", review: "a review")
}
