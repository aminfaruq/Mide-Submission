//
//  RestaurantListPresenterTests.swift
//  RestaurantAppTests
//
//  Created by Amin faruq on 01/11/26.
//

import XCTest
import RxSwift
import RestaurantCore
import RestaurantApp

protocol RestaurantListViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func showRestaurants(_ restaurants: [RestaurantItemViewModel])
    func showError(_ message: String)
}

protocol RestaurantListRouterProtocol: AnyObject {
    static func createModule() -> UIViewController
    
    func navigateToDetail(view: RestaurantListViewProtocol?, id: String)
}

final class RestaurantListPresenter {
    
    var view: RestaurantListViewProtocol?
    var interactor: RestaurantListInteractorProtocol?
    var router: RestaurantListRouterProtocol?
        
    private let disposeBag = DisposeBag()
    
    func viewDidLoad() {
        view?.showLoading()
        
        interactor?.loadRestaurants()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] results in
                    guard let self = self else { return }
                    view?.hideLoading()
                    view?.showRestaurants(results.map { RestaurantItemViewModel(from: $0) })
                },
                onFailure: { [weak self] error in
                    guard let self = self else { return }
                    view?.hideLoading()
                    view?.showError(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
}


final class RestaurantListPresenterTests: XCTestCase {

    func test_init_doesNotMessagesUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.viewMessages, [])
        XCTAssertEqual(spy.interactorMessage, [])
        XCTAssertEqual(spy.interactorCallCount, 0)
        XCTAssertEqual(spy.loadRouterId, "")
    }
    
    func test_viewDidLoad_deliversErrorOnFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        spy.interactorStub = .error(expectedError)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showError(expectedError.localizedDescription)
        ])
    }
    
    func test_viewDidLoad_deliversResultsOnSuccess() {
        let (sut, spy) = makeSUT()
        let results = [makeRestaurant(name: "melting"), makeRestaurant(name: "pot")]
        spy.interactorStub = .just(results)
        
        
        sut.viewDidLoad()
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showRestaurants(results.map { RestaurantItemViewModel(from: $0) })
        ])
    }
    
    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RestaurantListPresenter, spy: ViewSpy) {
        let sut = RestaurantListPresenter()
        let spy = ViewSpy()
        
        sut.view = spy
        sut.interactor = spy
        sut.router = spy
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        
        return (sut, spy)
    }
    
    private class ViewSpy: RestaurantListViewProtocol, RestaurantListInteractorProtocol, RestaurantListRouterProtocol {
       
      
        //MARK: - View
        enum ViewMessage: Equatable {
            case showLoading
            case hideLoading
            case showRestaurants(_ restaurants: [RestaurantItemViewModel])
            case showError(_ message: String)
        }
        
        private(set) var viewMessages = [ViewMessage]()
        
        func showLoading() {
            viewMessages.append(.showLoading)
        }
        
        func hideLoading() {
            viewMessages.append(.hideLoading)
        }
        
        func showRestaurants(_ restaurants: [RestaurantItemViewModel]) {
            viewMessages.append(.showRestaurants(restaurants))
        }
        
        func showError(_ message: String) {
            viewMessages.append(.showError(message))
        }
        
        
        //MARK: - Interactor
        enum InteractorMessage: Equatable {
            case request(query: String)
        }
        private(set) var interactorMessage = [InteractorMessage]()
        private(set) var interactorCallCount = 0
        var interactorStub: Single<[RestaurantEntity]> = .never()
        
        func loadRestaurants(query: String) -> Single<[RestaurantEntity]> {
            interactorMessage.append(.request(query: query))
            interactorCallCount += 1
            return interactorStub
        }
        
        //MARK: - Router
        var loadRouterId = ""
        static func createModule() -> UIViewController {  UIViewController() }
        
        func navigateToDetail(view: (any RestaurantListViewProtocol)?, id: String) {
            loadRouterId = id
        }
        
        
    }

}
