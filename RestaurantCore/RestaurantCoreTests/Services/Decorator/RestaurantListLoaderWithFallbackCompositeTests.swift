//
//  RestaurantListLoaderWithFallbackCompositeTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift
import XCTest
import RestaurantCore

final class RestaurantListLoaderWithFallbackCompositeTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_loadRestaurants_deliversPrimaryOnSuccess() {
        let (sut, primary, fallback) = makeSUT()
        
        let primaryResult = [makeRestaurant(name: "melting")]
        let fallbackResult = [makeRestaurant(name: "kopikita")]
        
        primary.stub = .just(primaryResult)
        fallback.stub = .just(fallbackResult)
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants(query: "")
            .subscribe(
                onSuccess: { results in
                    XCTAssertEqual(results, primaryResult)
                    XCTAssertEqual(fallback.loadCallCount, 0)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_deliversFallbackWhenPrimaryFail() {
        let (sut, primary, fallback) = makeSUT()
        
        let fallbackResult = [makeRestaurant(name: "kopikita")]
        
        primary.stub = .error(anyError())
        fallback.stub = .just(fallbackResult)
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants(query: "")
            .subscribe(
                onSuccess: { results in
                    XCTAssertEqual(results, fallbackResult)
                    XCTAssertEqual(fallback.loadCallCount, 1)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_deliversBothFailure() {
        let (sut, primary, fallback) = makeSUT()
        
        let expectedError = anyError()
        primary.stub = .error(anyError())
        fallback.stub = .error(anyError())
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants(query: "")
            .subscribe(
                onFailure: { error in
                    let receivedError = error as NSError
                    XCTAssertEqual(receivedError.domain, expectedError.domain)
                    XCTAssertEqual(receivedError.code, expectedError.code)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RestaurantListLoaderWithFallbackComposite,
        primary: LoaderSpy,
        fallback: LoaderSpy,
    ) {
        let primary = LoaderSpy()
        let fallback = LoaderSpy()
        let sut = RestaurantListLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        
        trackForMemoryLeaks(primary, file: file, line: line)
        trackForMemoryLeaks(fallback, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primary, fallback)
    }
    
    private class LoaderSpy: RestaurantListLoader {
        private(set) var loadCallCount = 0
        var stub: Single<[RestaurantEntity]> = .never()
        
        func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
            loadCallCount += 1
            return stub
        }
        
    }
}
