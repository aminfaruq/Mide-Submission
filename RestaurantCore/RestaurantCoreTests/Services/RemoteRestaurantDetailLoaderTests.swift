//
//  RemoteRestaurantDetailLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import XCTest

public struct AddReviewBody: Hashable {
    public let id: String
    public let name: String
    public let review: String
    
    public init(id: String, name: String, review: String) {
        self.id = id
        self.name = name
        self.review = review
    }
}


final class RemoteRestaurantDetailLoader {
    
    init(url: URL, client: HTTPClient) {
        
    }
}

final class RemoteRestaurantDetailLoaderTests: XCTestCase {
    
    
    //MARK: - Helpers
    private func makeSUT(
        url: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RemoteRestaurantDetailLoader,
        spy: HTTPClientSpy
    ) {
        let spy = HTTPClientSpy()
        let sut = RemoteRestaurantDetailLoader(url: url, client: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
    private func makeReview() -> AddReviewBody {
        .init(id: "trurtgjx", name: "a name", review: "a review")
    }
    
    private func makeBody(id: String, name: String, review: String) -> HTTPBody {
        let json: [String: Any] = [
            "id": id,
            "name": name,
            "review": review
        ]
        
        let data = try! JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
        return HTTPBody(data: data, contentType: .json)
    }
    
    private func makeRestaurant(_ restaurant: [String: Any]) -> Data {
        let json: [String: Any] = [
            "restaurant": restaurant
        ]
        
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeResult(
        id: String,
        input: String = "a string",
        rating: Double = 0,
    ) -> (model: RestaurantDetailEntity, json: [String: Any]) {
        let model = RestaurantDetailEntity(
            id: id,
            name: input,
            description: input,
            city: input,
            address: input,
            pictureId: input,
            categories: [
                CategoryEntity(name: input)
            ],
            menus: MenuEntity(
                foods: [
                    CategoryEntity(name: input)
                ],
                drinks: [
                    CategoryEntity(name: input)
                ]),
            rating: rating,
            customerReviews: [
                CustomerReviewEntity(name: input, review: input, date: input)
            ]
        )
        
        let json: [String: Any] = [
            "id": id,
            "name": input,
            "description": input,
            "city": input,
            "address": input,
            "pictureId": input,
            "categories": [makeNames(input: input)],
            "menus": makeMenus(input: [makeNames(input: input)]),
            "rating": rating,
            "customerReviews": [makeCustomerReviews(input: input)]
        ]
        return (model, json)
    }
    
    private func makeCustomerReviews(input: String) -> [String: Any] {
        let json: [String: Any] = [
            "name": input,
            "review": input,
            "date": input
        ]
        return json
    }
    
    private func makeNames(input: String) -> [String: Any] {
        let json: [String: Any] = [
            "name": input,
        ]
        return json
    }
    
    private func makeMenus(input: [[String: Any]]) -> [String: Any] {
        let json: [String: Any] = [
            "foods": input,
            "drinks": input,
        ]
        return json
    }
}
