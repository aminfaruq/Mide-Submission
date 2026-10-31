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
        .never()
    }
    
}

final class RestaurantListLoaderCacheDecoratorTests: XCTestCase {
    
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
        // MARK: - Loader
        func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
            .never()
        }
        
        // MARK: - Saver
        func save(_ restaurants: [RestaurantEntity]) -> Completable {
            .never()
        }
    }
}
