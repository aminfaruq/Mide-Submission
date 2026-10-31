//
//  LocalFavoriteRestaurantListLoaderTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

final class LocalFavoriteRestaurantListLoaderTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotMessagesUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_loadRestaurants_requestsRetrieveFromStore() {
        let (sut, spy) = makeSUT()
        
        sut.loadRestaurants()
            .subscribe()
            .disposed(by: disposeBag)
        
        XCTAssertEqual(spy.messages, [.retrieve])
    }
    
    func test_loadRestaurants_deliversErrorOnFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        spy.retrieveStub = .error(expectedError)
        
        let exp = expectation(description: "wait from store")
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
    
    func test_loadRestaurants_deliversEmptyFromStore() {
        let (sut, spy) = makeSUT()
        spy.retrieveStub = .just([])
        
        let exp = expectation(description: "wait from store")
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
    
    func test_loadRestaurants_deliversAllItemsOnEmptyQuery() {
        let (sut, spy) = makeSUT()
        let items = [makeRestaurant(name: "A"), makeRestaurant(name: "B")]
        spy.retrieveStub = .just(items)
        
        let exp = expectation(description: "wait from store")
        sut.loadRestaurants()
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, items)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_filtersMatchingQueryByName() {
        let (sut, spy) = makeSUT()
        let rest1 = makeRestaurant(name: "Melting pot")
        let rest2 = makeRestaurant(name: "kopi pangku")
        spy.retrieveStub = .just([rest1, rest2])
        
        let exp = expectation(description: "wait from store")
        sut.loadRestaurants(query: "Melting")
            .subscribe(
                onSuccess: { result in
                    XCTAssertEqual(result, [rest1])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFavoriteRestaurantListLoader, spy: FavoriteStoreSpy) {
        let spy = FavoriteStoreSpy()
        let sut = LocalFavoriteRestaurantListLoader(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
}
