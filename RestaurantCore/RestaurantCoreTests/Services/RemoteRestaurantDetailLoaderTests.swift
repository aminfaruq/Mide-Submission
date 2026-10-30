//
//  RemoteRestaurantDetailLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import XCTest
import RxSwift

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
    private let url: URL
    private let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
        let requestedURL = url
            .appending(path: "detail")
            .appending(path: "\(id)")
        return client.get(from: requestedURL)
            .catch({ _ in
                return .error(NetworkError.connectivity)
            })
            .flatMap { data, response in
                
                switch response.statusCode {
                    case 200:
                        guard let root = try? JSONDecoder().decode(RootDTO.self, from: data) else {
                            return .error(NetworkError.decodeError)
                        }
                        
                        return .just(root.restaurant.toModel())
                    default:
                        return .error(NetworkError.invalidData)
                }
            }
    }
    
    private struct RootDTO: Decodable {
        let restaurant: RemoteRestaurantDTO
    }
    
    private struct RemoteRestaurantDTO: Decodable {
        private let id, name, description, city: String
        private let address, pictureId: String
        private let categories: [CategoryDTO]
        private let menus: MenusDTO
        private let rating: Double
        private let customerReviews: [CustomerReviewDTO]
        
        func toModel() -> RestaurantDetailEntity {
            .init(
                id: id,
                name: name,
                description: description,
                city: city,
                address: address,
                pictureId: pictureId,
                categories: categories.map { $0.toModel() },
                menus: menus.toModel(),
                rating: rating,
                customerReviews: customerReviews.map { $0.toModel() })
        }
    }
    
    private struct CategoryDTO: Decodable {
        private let name: String
        
        func toModel() -> CategoryEntity {
            .init(name: name)
        }
    }
    
    private struct CustomerReviewDTO: Decodable {
        private let name, review, date: String
        
        func toModel() -> CustomerReviewEntity {
            .init(name: name, review: review, date: date)
        }
    }
    
    private struct MenusDTO: Decodable {
        private let foods, drinks: [CategoryDTO]
        
        func toModel() -> MenuEntity {
            .init(foods: foods.map { $0.toModel() }, drinks: drinks.map { $0.toModel() })
        }
    }
    
}

final class RemoteRestaurantDetailLoaderTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.requestedURL, [])
    }
    
    func test_loadRestaurantDetail_requestedFromURL() {
        let id = "an-id"
        let url = anyURL()
        let (sut, spy) = makeSUT(url: url)
        
        let expectedURL = URL(string: url.absoluteString + "/detail/\(id)")
        
        sut.loadRestaurantDetail(id: id)
            .subscribe()
            .disposed(by: disposeBag)
        
        XCTAssertEqual(spy.requestedURL, [expectedURL])
    }
    
    func test_loadRestaurantDetail_deliversErrorConnectivity() {
        let (sut, spy) = makeSUT()
        spy.stub = .error(anyError())
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurantDetail(id: "an-id")
            .subscribe(
                onFailure: { error in
                    let receivedError = error as? NetworkError
                    XCTAssertEqual(receivedError, .connectivity)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurantDetail_deliversInvalidDataOnNon200() {
        let samples = [199, 300, 400, 404, 500]
        
        samples.forEach { code in
            let (sut, spy) = makeSUT()
            spy.stub = .just(makeResponse(statusCode: code))
            
            let exp = expectation(description: "wait from response")
            sut.loadRestaurantDetail(id: "an-id")
                .subscribe(
                    onFailure: { error in
                        let receivedError = error as? NetworkError
                        XCTAssertEqual(receivedError, .invalidData)
                        exp.fulfill()
                    }
                )
                .disposed(by: disposeBag)
            
            wait(for: [exp], timeout: 1.0)
        }
    }
    
    func test_loadRestaurantDetail_deliversDecodeErrorOn200StatusCode() {
        let (sut, spy) = makeSUT()
        let invalidJSON = "invalid-json".data(using: .utf8)!
        
        spy.stub = .just(makeResponse(statusCode: 200, data: invalidJSON))
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurantDetail(id: "an-id")
            .subscribe(
                onFailure: { error in
                    let receivedError = error as? NetworkError
                    XCTAssertEqual(receivedError, .decodeError)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurantDetail_deliversResultsOn200StatusCode() {
        let (sut, spy) = makeSUT()
        let restaurant = makeResult(id: "any-id")
        let json = makeRestaurant(restaurant.json)
        
        spy.stub = .just(makeResponse(statusCode: 200, data: json))
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurantDetail(id: "an-id")
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, restaurant.model)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
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
