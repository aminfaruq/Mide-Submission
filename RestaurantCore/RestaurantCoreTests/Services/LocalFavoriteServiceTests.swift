//
//  LocalFavoriteServiceTests.swift
//  RestaurantCoreTests
//
//  Created by Amin faruq on 31/10/26.
//

import XCTest
import RxSwift
import RestaurantCore

final class LocalFavoriteServiceTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    func test_init_doesNotMessagesUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.messages, [])
    }
    
    func test_save_requestSaveFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.saveStub = .empty()
        let exp = expectation(description: "wait from response")
        let insertion = makeRestaurant(name: "melting")
        
        sut.save(insertion)
            .subscribe(
                onCompleted: {
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.save(insertion)])
    }
    
    func test_remove_requestDeleteFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.deleteStub = .empty()
        let exp = expectation(description: "wait from response")
        let anyId = UUID().uuidString
        
        sut.remove(id: anyId)
            .subscribe(
                onCompleted: {
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.delete(id: anyId)])
    }
    
    func test_isFavorite_requestFavoriteFromStore() {
        let (sut, spy) = makeSUT()
        
        spy.isFavoriteStub = .just(true)
        let exp = expectation(description: "wait from response")
        let anyId = UUID().uuidString
        
        sut.isFavorite(id: anyId)
            .subscribe(
                onSuccess: { result in
                    XCTAssertTrue(result)
                    exp.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(spy.messages, [.isFavorite(id: anyId)])
    }

    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFavoriteService, spy: FavoriteStoreSpy) {
        let spy = FavoriteStoreSpy()
        let sut = LocalFavoriteService(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }

}
