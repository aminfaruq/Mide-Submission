//
//  RemoteRestaurantListLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import XCTest
import RxSwift

public struct HTTPBody: Equatable {
    enum ContentType: Equatable {
        case json
    }
    
    private let data: Data
    private let contentType: ContentType
    
    init(data: Data, contentType: ContentType) {
        self.data = data
        self.contentType = contentType
    }
}

public protocol HTTPClient {
    typealias Result = (Data, HTTPURLResponse)
    
    func get(from url: URL) -> Single<Result>
    func post(to url: URL, body: HTTPBody?) -> Single<Result>
}

final class RemoteRestaurantListLoader {
    
    init(url: URL, client: HTTPClient) {
        
    }
}

final class RemoteRestaurantListLoaderTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.requestedURL, [])
    }
    
    func test_loadRestaurants_requestedFromURL() {
        let url = anyURL()
        let (sut, spy) = makeSUT(url: url)
        
        XCTAssertEqual(spy.requestedURL, [])
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
