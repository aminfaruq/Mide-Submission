//
//  LocalCacheSaverTests.swift
//  RestaurantCore
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

final class LocalCacheSaverTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotMessageUponCreation() {
        let (_, spy) = makeSUT()
        
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_save_messageOnSave() {
        let (sut, spy) = makeSUT()
        
        let items = [makeRestaurant(name: "melting")]
        
        sut.save(items)
            .subscribe()
            .disposed(by: disposeBag)
        
        XCTAssertEqual(spy.messages, [.save(items)])
    }
    
    func test_save_requestSaveOnFailure() {
        let (sut, spy) = makeSUT()
        
        let expectedError = anyError()
        spy.saveStub = .error(expectedError)
        
        let exp = expectation(description: "wait from response")
        
        sut.save([makeRestaurant(name: "melting")])
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
    
    func test_save_requestSaveOnSuccess() {
        let (sut, spy) = makeSUT()
        
        let items = [makeRestaurant(name: "melting")]
        spy.saveStub = .empty()
        
        let exp = expectation(description: "wait from response")
        sut.save(items)
            .subscribe(
               onCompleted: {
                   exp.fulfill()
               }
            )
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.save(items)])
    }
    
    
    //MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalCacheSaver, spy: CacheStoreSpy) {
        let spy = CacheStoreSpy()
        let sut = LocalCacheSaver(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
    private func makeRestaurant(name: String) -> RestaurantEntity {
        .init(
            id: UUID().uuidString,
            name: name,
            description: "a desc",
            pictureId: "an id",
            city:  "any-city",
            rating: 4.5
        )
    }
    
    private class CacheStoreSpy: CacheStore {
        enum Message: Equatable {
            case retrieve
            case save(_ restaurants: [RestaurantEntity])
        }
        
        private(set) var messages = [Message]()
        
        var retriveStub: Single<[RestaurantEntity]> = .never()
        var saveStub: Completable = .never()
        
        func retrieve() -> Single<[RestaurantEntity]> {
            messages.append(.retrieve)
            return retriveStub
        }
        
        func save(_ restaurants: [RestaurantEntity]) -> Completable {
            messages.append(.save(restaurants))
            return saveStub
        }
    }
}
