//
//  RestaurantListPresenterTests.swift
//  RestaurantAppTests
//
//  Created by Amin faruq on 01/11/26.
//

import XCTest
import RxSwift
import RxTest
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
    
    private var searchSubject = PublishSubject<String>()
        
    private let disposeBag = DisposeBag()
    
    private let scheduler: SchedulerType
    private let dueTime: RxTimeInterval
    
    public init(scheduler: SchedulerType = MainScheduler.instance, dueTime: RxTimeInterval = .milliseconds(300)) {
        self.scheduler = scheduler
        self.dueTime = dueTime
        setupSearchPipeline()
    }
    
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
    
    func didSearch(_ query: String) {
        searchSubject.onNext(query)
    }
    
    private func setupSearchPipeline() {
        searchSubject
            .subscribe(
                onNext: { [weak self] query in
                    guard let self = self else { return }
                    executeSearch(query: query)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func executeSearch(query: String) {
        view?.showLoading()
        
        interactor?.loadRestaurants(query: query)
            .observe(on: MainScheduler.instance)
            .subscribe(
//                onSuccess: { [weak self] results in
//                    guard let self = self else { return }
//                    view?.hideLoading()
//                    view?.showRestaurants(results.map { RestaurantItemViewModel(from: $0) })
//                },
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
        let (_, spy, _) = makeSUT()
        
        XCTAssertEqual(spy.viewMessages, [])
        XCTAssertEqual(spy.interactorMessage, [])
        XCTAssertEqual(spy.interactorCallCount, 0)
        XCTAssertEqual(spy.loadRouterId, "")
    }
    
    func test_viewDidLoad_deliversErrorOnFailure() {
        let (sut, spy, _) = makeSUT()
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
        let (sut, spy, _) = makeSUT()
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
    
    func test_didSearch_deliversErrorOnFailure() {
        let (sut, spy, _) = makeSUT()
        let expectedError = anyError()
        spy.interactorStub = .error(expectedError)
        
        sut.didSearch("")
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showError(expectedError.localizedDescription)
        ])
    }
    
    func test_didSearch_requestSearchWithInitialPageAndShowsLoading() {
        let (sut, spy, scheduler) = makeSUT()
        let query = "Melting"
        
        sut.didSearch(query)
        scheduler.advanceTo(300)
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.viewMessages, [.showLoading])
        XCTAssertEqual(spy.interactorMessage.last, .request(query: query))
    }
    
    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RestaurantListPresenter, spy: ViewSpy, scheduler: TestScheduler) {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = RestaurantListPresenter()
        let spy = ViewSpy()
        
        sut.view = spy
        sut.interactor = spy
        sut.router = spy
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        
        return (sut, spy, scheduler)
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
