//
//  RestaurantDetailInteractorTests.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import XCTest
import RxSwift
import RestaurantCore
import RestaurantApp

final class RestaurantDetailInteractor {
    
    init(loader: RestaurantDetailLoader, service: FavoriteService) {
        
    }
}

final class RestaurantDetailInteractorTests: XCTestCase {
    
    func test_init_doesNotRequestFromLoaderOrService() {}
    
    func test_fetchRestaurantDetail_deliversErrorOnFailure() {}
    
    func test_fetchRestaurantDetail_deliversResultOnSuccess() {}
    
    func test_addReview_deliversErrorOnFailure() {}
    
    func test_addReview_deliversOnComplete() {}
    
    func test_isFavorite_deliversErrorOnFailure() {}
    
    func test_isFavorite_deliversStatusOnSuccess() {}
    
    func test_toggleFavorite_savesWhenNotFavorite() {}
    
    func test_toggleFavorite_removesWhenAllreadyFavorite() {}
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RestaurantDetailInteractor,
        spy: InteractorSpy
    ) {
        let spy = InteractorSpy()
        let sut = RestaurantDetailInteractor(loader: spy, service: spy)
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private class InteractorSpy: RestaurantDetailLoader, FavoriteService {
        
        // MARK: - Loader
        private(set) var loadCallCount = 0
        private var loadStub: Single<RestaurantDetailEntity> = .never()
        
        private(set) var addReviewCallCount = 0
        private var addReviewStub: Completable = .never()
        
        func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
            loadCallCount += 1
            return loadStub
        }
        
        func addReview(review: AddReviewBody) -> Completable {
            addReviewCallCount += 1
            return addReviewStub
        }
        
        // MARK: - Favorite
        private(set) var saveCallCount = 0
        private(set) var removeCallCount = 0
        private(set) var isFavoriteCallCount = 0

        var saveStub: Completable = .never()
        var removeStub: Completable = .never()
        var isFavoriteStub: Single<Bool> = .never()

        func save(_ restaurant: RestaurantEntity) -> Completable {
            saveCallCount += 1
            return saveStub
        }
        
        func remove(id: String) -> Completable {
            removeCallCount += 1
            return removeStub
        }
        
        func isFavorite(id: String) -> Single<Bool> {
            isFavoriteCallCount += 1
            return isFavoriteStub
        }
    }
}
