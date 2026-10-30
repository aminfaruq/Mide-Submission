//
//  URLSessionHTTPClientTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import RxSwift
import XCTest

final class URLSessionHTTPClient {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL) -> Single<HTTPClient.Result> {
        return Single.create { [session] single in
            let task = session.dataTask(with: url) { _, _, error in
                if let error {
                    single(.failure(error))
                    return
                }
                
            }
            
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stub = nil
    }
    
    func test_getFromURL_requestFromURL() {
        let url = anyURL()
        let exp = expectation(description: "wait from response")
        
        URLProtocolStub.stub = { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
            return makeResponse(statusCode: 200)
        }
        
        makeSUT().get(from: url)
            .subscribe()
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_deliversErrorOnFailure() {
        let expectedError = anyError()
        let exp = expectation(description: "wait from response")

        URLProtocolStub.stub = { _ in
            throw expectedError
        }
        
        makeSUT().get(from: anyURL())
            .subscribe(
                onFailure: { error in
                    let receivedError = error as NSError
                    XCTAssertEqual(receivedError.code, expectedError.code)
                    XCTAssertEqual(receivedError.domain, expectedError.domain)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }

    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stub: ((URLRequest) throws -> (Data, URLResponse))?
        
        override class func canInit(with request: URLRequest) -> Bool {
            return URLProtocolStub.stub != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }
            
            do {
                let (data, response) = try stub(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {}
    }
}
