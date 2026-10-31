//
//  LocalCacheRestaurantListLoaderTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

final class LocalCacheRestaurantListLoader: RestaurantListLoader {
    
    private let store: CacheStore
    
    init(store: CacheStore) {
        self.store = store
    }
    
    func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
        .never()
    }
    
}

final class LocalCacheRestaurantListLoaderTests: XCTestCase {
    
    //MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalCacheRestaurantListLoader, spy: CacheStoreSpy) {
        let spy = CacheStoreSpy()
        let sut = LocalCacheRestaurantListLoader(store: spy)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        return (sut, spy)
    }
    
}
