//
//  RemoteRestaurantDetailLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import XCTest
import RxSwift

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
    
    func test_addReview_requestedFromURL() {
        let url = anyURL()
        let (sut, spy) = makeSUT(url: url)
        
        let expectedURL = URL(string: url.absoluteString + "/review")!
        
        let review = makeReview()
        let body = makeBody(id: review.id, name: review.name, review: review.review)
        
        sut.addReview(review: review)
            .subscribe()
            .disposed(by: disposeBag)
        
        XCTAssertEqual(spy.messages, [.post(expectedURL, body: body)])
    }
    
    
    func test_addReview_deliversErrorConnectivity() {
        let (sut, spy) = makeSUT()
        spy.stub = .error(anyError())
        
        let exp = expectation(description: "wait from response")
        
        sut.addReview(review: makeReview())
            .subscribe(
                onError: { error in
                    let receivedError = error as? NetworkError
                    XCTAssertEqual(receivedError, .connectivity)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_addReview_deliversInvalidDataOnNon201() {
        let samples = [199, 200, 300, 400, 404, 500]
        
        samples.forEach { code in
            let (sut, spy) = makeSUT()
            spy.stub = .just(makeResponse(statusCode: code))
            
            let exp = expectation(description: "wait from response")
            sut.addReview(review: makeReview())
                .subscribe(
                    onError: { error in
                        let receivedError = error as? NetworkError
                        XCTAssertEqual(receivedError, .invalidData)
                        exp.fulfill()
                    }
                )
                .disposed(by: disposeBag)
            
            wait(for: [exp], timeout: 1.0)
        }
    }
    
    func test_addReview_deliversCompletedOn201StatusCode() {
        let (sut, spy) = makeSUT()
        spy.stub = .just(makeResponse(statusCode: 201))
        
        let exp = expectation(description: "wait from response")
        sut.addReview(review: makeReview())
            .subscribe(
                onCompleted: {
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
