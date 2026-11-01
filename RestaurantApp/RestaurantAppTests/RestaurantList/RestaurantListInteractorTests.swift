//
//  RestaurantListInteractorTests.swift
//  RestaurantAppTests
//
//  Created by Amin faruq on 01/11/26.
//

import XCTest
import RestaurantCore
import RestaurantApp
import RxSwift

final class RestaurantListInteractorTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotRequestFromLoader() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.loadCallCount, 0)
    }
    
    func test_loadRestaurants_deliversErrorOnFailure() {
        let (sut, spy) = makeSUT()
        
        let expectedError = anyError()
        spy.stub = .error(expectedError)
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants()
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
    
    func test_loadRestaurants_deliversResultsOnSuccess() {
        let (sut, spy) = makeSUT()
        
        let results = [makeRestaurant(name: "a name")]
        spy.stub = .just(results)
        
        let exp = expectation(description: "wait from response")
        
        sut.loadRestaurants()
            .subscribe(
                onSuccess: { receivedResults in
                    XCTAssertEqual(receivedResults, results)
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
    ) -> (
        sut: RestaurantListInteractor,
        spy: LoaderSpy
    ) {
        let spy = LoaderSpy()
        let sut = RestaurantListInteractor(loader: spy)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        return (sut, spy)
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
