//
//  URLSessionHTTPClientTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import RxSwift
import XCTest

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
    
    func test_getFromURL_deliversErrorOnNonHTTURLResponse() {
        let data = "any-data".data(using: .utf8)!
        let response = URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        
        URLProtocolStub.stub = { _ in
            return (data, response)
        }
        
        let exp = expectation(description: "wait from response")
        makeSUT().get(from: anyURL())
            .subscribe(
                onFailure: { error in
                    XCTAssertTrue(error is URLSessionHTTPClient.UnexpectedValuesRepresentation)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_deliversResultFromURL() {
        let (data, response) = makeResponse(statusCode: 200, data: "any-data".data(using: .utf8)!)
        
        URLProtocolStub.stub = { _ in
            return (data, response)
        }
        
        let exp = expectation(description: "wait from response")
        makeSUT().get(from: anyURL())
            .subscribe(
                onSuccess: { receivedData, receivedResponse in
                    XCTAssertEqual(receivedData, data)
                    XCTAssertEqual(receivedResponse.url, response.url)
                    XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_postToURL_requestFromURL() {
        let url = anyURL()
        let exp = expectation(description: "wait from response")
        let jsonBody = "{\"title\": \"ABC\"}".data(using: .utf8)!
        let body = HTTPBody(data: jsonBody, contentType: .json)
        
        URLProtocolStub.stub = { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.httpBodyData, jsonBody)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            exp.fulfill()
            return makeResponse(statusCode: 200)
        }
        
        makeSUT().post(to: url, body: body)
            .subscribe()
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_postToURL_deliversErrorOnFailure() {
        let expectedError = anyError()
        let exp = expectation(description: "wait from response")
        
        URLProtocolStub.stub = { _ in
            throw expectedError
        }
        
        makeSUT().post(to: anyURL(), body: nil)
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
    
    func test_postToURL_deliversErrorOnNonHTTURLResponse() {
        let data = "any-data".data(using: .utf8)!
        let response = URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        
        URLProtocolStub.stub = { _ in
            return (data, response)
        }
        
        let exp = expectation(description: "wait from response")
        makeSUT().post(to: anyURL(), body: nil)
            .subscribe(
                onFailure: { error in
                    XCTAssertTrue(error is URLSessionHTTPClient.UnexpectedValuesRepresentation)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_postToURL_deliversResultFromURL() {
        let (data, response) = makeResponse(statusCode: 200, data: "any-data".data(using: .utf8)!)
        
        URLProtocolStub.stub = { _ in
            return (data, response)
        }
        
        let exp = expectation(description: "wait from response")
        makeSUT().post(to: anyURL(), body: nil)
            .subscribe(
                onSuccess: { receivedData, receivedResponse in
                    XCTAssertEqual(receivedData, data)
                    XCTAssertEqual(receivedResponse.url, response.url)
                    XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
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

private extension URLRequest {
    var httpBodyData: Data? {
        if let httpBody = httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data
    }
}
