//
//  RestaurantListLoaderCacheDecoratorTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RestaurantCore
import RxSwift

final class RestaurantListLoaderCacheDecorator: RestaurantListLoader {
    
    private let decoratee: RestaurantListLoader
    private let cache: CacheSaver
    
    init(decoratee: RestaurantListLoader, cache: CacheSaver) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
        return decoratee.loadRestaurants(query: query)
            .flatMap { [weak self] results in
                guard let self = self else { return .just(results) }
                return self.cache.save(results)
                    .catch { _ in .empty() }
                    .andThen(Single.just(results))
            }
    }
    
}

final class RestaurantListLoaderCacheDecoratorTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotMessageUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_loadRestaurants_deliversDecorateeOnFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        
        spy.loadStub = .error(expectedError)

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
    
    func test_loadRestaurants_deliversDecorateeOnSuccess() {
        let (sut, spy) = makeSUT()
        let expectedResults = [
            makeRestaurant(name: "melting"),
            makeRestaurant(name: "pot")
        ]

        spy.loadStub = .just(expectedResults)
        spy.saveStub = .empty()
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants(query: "")
            .subscribe(
                onSuccess: { receivedResults in
                    XCTAssertEqual(receivedResults, expectedResults)
                    XCTAssertTrue(spy.messages.contains(.loadRestaurants(query: "")) )
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_deliversDecorateeOnSuccessWhenHaveQuery() {
        let (sut, spy) = makeSUT()
        
        spy.loadStub = .just([makeRestaurant(name: "melting")])
        spy.saveStub = .empty()
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants(query: "melting")
            .subscribe(
                onSuccess: { _ in
                    XCTAssertTrue(spy.messages.contains(.loadRestaurants(query: "melting")) )
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_cacheOnSuccess() {
        let (sut, spy) = makeSUT()
        let expectedResults = [
            makeRestaurant(name: "melting"),
            makeRestaurant(name: "pot")
        ]

        spy.loadStub = .just(expectedResults)
        spy.saveStub = .empty()
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants(query: "")
            .subscribe(
                onSuccess: { _ in
                    XCTAssertEqual(spy.messages, [
                        .loadRestaurants(query: ""),
                        .save(expectedResults)
                    ])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_cacheOnFailure() {
        let (sut, spy) = makeSUT()
        
        spy.loadStub = .error(anyError())
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants(query: "")
            .subscribe(
                onFailure: { _ in
                    XCTAssertEqual(spy.messages, [.loadRestaurants(query: "")])
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadRestaurants_deliversDecorateeResultEvenIfCacheSaveFails() {
        let (sut, spy) = makeSUT()
        let expectedResult = makeRestaurant(name: "melting")
        spy.loadStub = .just([expectedResult])
        spy.saveStub = .error(anyError())
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurants(query: "")
            .subscribe(
                onSuccess: { results in
                    XCTAssertEqual(results, [expectedResult])
                    XCTAssertTrue(spy.messages.contains(.loadRestaurants(query: "")))
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RestaurantListLoaderCacheDecorator,
        spy: DecoratorSpy
    ) {
        let spy = DecoratorSpy()
        let sut = RestaurantListLoaderCacheDecorator(decoratee: spy, cache: spy)
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private class DecoratorSpy: RestaurantListLoader, CacheSaver {
        enum Message: Equatable {
            case loadRestaurants(query: String)
            case save(_ restaurants: [RestaurantEntity])
        }
        
        private(set) var messages = [Message]()
        
        var loadStub: Single<[RestaurantEntity]> = .never()
        var saveStub: Completable = .never()
        
        // MARK: - Loader
        func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
            messages.append(.loadRestaurants(query: query))
            return loadStub
        }
        
        // MARK: - Saver
        func save(_ restaurants: [RestaurantEntity]) -> Completable {
            messages.append(.save(restaurants))
            return saveStub
        }
    }
}
