//
//  RemoteRestaurantListLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import XCTest
import RxSwift

final class RemoteRestaurantListLoaderTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.requestedURL, [])
    }
    
    func test_loadRestaurants_requestedFromURL() {
        let url = anyURL()
        let (sut, spy) = makeSUT(url: url)
        
        let expectedURL = URL(string: url.absoluteString + "/search?q=melting")
        
        sut.loadRestaurants(query: "melting")
            .subscribe()
            .disposed(by: disposeBag)
        
        XCTAssertEqual(spy.requestedURL, [expectedURL])
    }
    
    func test_loadRestaurants_deliversErrorConnectivity() {
        let (sut, spy) = makeSUT()
        let anyError = NSError(domain: "an-error", code: -99999)
        spy.stub = .error(anyError)
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants()
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
    
    func test_loadRestaurants_deliversInvalidDataOnNon200() {
        let samples = [199, 300, 400, 404, 500]
        
        samples.forEach { code in
            let (sut, spy) = makeSUT()
            spy.stub = .just(makeResponse(statusCode: code))
            
            let exp = expectation(description: "wait from response")
            sut.loadRestaurants()
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
    
    func test_loadRestaurants_deliversDecodeErrorOn200StatusCode() {
        let (sut, spy) = makeSUT()
        let invalidJSON = "invalid-json".data(using: .utf8)!
        
        spy.stub = .just(makeResponse(statusCode: 200, data: invalidJSON))
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants()
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
    
    func test_loadRestaurants_deliversEmptyOn200StatusCode() {
        let (sut, spy) = makeSUT()
        let json = makeResult([])
        spy.stub = .just(makeResponse(statusCode: 200, data: json))
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants()
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_deliversResultsOn200StatusCode() {
        let (sut, spy) = makeSUT()
        let restaurant = makeRestaurant()
        let json = makeResult([restaurant.json])
        
        spy.stub = .just(makeResponse(statusCode: 200, data: json))
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants()
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [restaurant.model])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helpers
    private func makeSUT(
        url: URL = anyURL()
    ) -> (
        sut: RemoteRestaurantListLoader,
        spy: HTTPClientSpy
    ) {
        let spy = HTTPClientSpy()
        let sut = RemoteRestaurantListLoader(url: url, client: spy)
        
        return (sut, spy)
    }
    
    private func makeResult(_ restaurants: [[String: Any]] ) -> Data {
        let json: [String: Any] = [
            "restaurants": restaurants
        ]
        
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeRestaurant(
        id: String = "an-id",
        name: String = "a name",
        description: String = "a description",
        pictureId: String = "a pictureId",
        city: String = "a city",
        rating: Double = 4.6
    ) -> (model: RestaurantEntity, json: [String: Any]) {
        let model = RestaurantEntity(
            id: id,
            name: name,
            description: description,
            pictureId: pictureId,
            city: city,
            rating: rating
        )
        
        let json: [String: Any] = [
            "id" : id,
            "name": name,
            "description": description,
            "pictureId": pictureId,
            "city": city,
            "rating": rating,
        ]
        
        return (model, json)
    }
    
    private class HTTPClientSpy: HTTPClient {
        
        enum Message: Equatable {
            case get(URL)
            case post(URL, body: HTTPBody?)
        }
        
        private(set) var messages = [Message]()
        
        var requestedURL: [URL] {
            messages.map { data in
                switch data {
                    case let .get(url):
                        return url
                    case let .post(url, _):
                        return url
                }
            }
        }
        
        var stub: Single<HTTPClient.Result> = .never()
        
        func get(from url: URL) -> Single<HTTPClient.Result> {
            messages.append(.get(url))
            return stub
        }
        
        func post(to url: URL, body: HTTPBody?) -> Single<HTTPClient.Result> {
            messages.append(.post(url, body: body))
            return stub
        }
    }
    
}

func anyError() -> NSError {
    NSError(domain: "an-error", code: -99999)
}

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func makeResponse(
    statusCode code: Int,
    data: Data = Data(),
    headers: [String: String]? = nil
) -> HTTPClient.Result {
    let response = HTTPURLResponse(
        url: anyURL(),
        statusCode: code,
        httpVersion: nil,
        headerFields: headers
    )!
    return (data, response)
}
