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
    
    private let loader: RestaurantDetailLoader
    private let service: FavoriteService
    
    init(loader: RestaurantDetailLoader, service: FavoriteService) {
        self.loader = loader
        self.service = service
    }
    
    func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
        return loader.loadRestaurantDetail(id: id)
    }
    
    func addReview(body: AddReviewBody) -> Completable {
        return loader.addReview(review: body)
    }
}

final class RestaurantDetailInteractorTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotRequestFromLoaderOrService() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.loadCallCount, 0)
        XCTAssertEqual(spy.addReviewCallCount, 0)
    }
    
    func test_loadRestaurantDetail_deliversErrorOnFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        spy.loadStub = .error(expectedError)
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurantDetail(id: anyId())
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
    
    func test_loadRestaurantDetail_deliversResultOnSuccess() {
        let (sut, spy) = makeSUT()
        let result = makeDetailRestaurant(name: "melting pot")
        spy.loadStub = .just(result)
        
        let exp = expectation(description: "wait from response")
        sut.loadRestaurantDetail(id: anyId())
            .subscribe(
                onSuccess: { receivedResult in
                    XCTAssertEqual(receivedResult, result)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_addReview_deliversErrorOnFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        spy.addReviewStub = .error(expectedError)
        
        let exp = expectation(description: "wait from response")
        sut.addReview(body: makeReview())
            .subscribe(
                onError: { error in
                    let receivedError = error as NSError
                    XCTAssertEqual(receivedError.domain, expectedError.domain)
                    XCTAssertEqual(receivedError.code, expectedError.code)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_addReview_deliversOnComplete() {
        let (sut, spy) = makeSUT()
        spy.addReviewStub = .empty()
        
        let exp = expectation(description: "wait from response")
        sut.addReview(body: makeReview())
            .subscribe(
                onCompleted: {
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
    }
    
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
        var loadStub: Single<RestaurantDetailEntity> = .never()
        
        private(set) var addReviewCallCount = 0
        var addReviewStub: Completable = .never()
        
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
