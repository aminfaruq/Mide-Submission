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
    
    weak var view: RestaurantListViewProtocol?
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
        executeSearch()
    }
    
    func didSearch(_ query: String) {
        searchSubject.onNext(query)
    }
    
    func didSelectRestaurant(id: String) {
        router?.navigateToDetail(view: view, id: id)
    }
    
    private func setupSearchPipeline() {
        searchSubject
            .debounce(dueTime, scheduler: scheduler)
            .startWith("")
            .scan((previous: "", current: "")) { state, newQuery in
                let cleanNew = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                return (previous: state.current, current: cleanNew)
            }
            .skip(1) // Optional
            .filter { $0.previous != $0.current }
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    
                    if state.current.isEmpty {
                        self.executeSearch(query: "")
                    } else {
                        self.executeSearch(query: state.current)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func executeSearch(query: String = "") {
        view?.showLoading()
        
        interactor?.loadRestaurants(query: query)
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
        let (_, spy, _) = makeSUT()
        
        XCTAssertEqual(spy.viewMessages, [])
        XCTAssertEqual(spy.interactorMessage, [])
        XCTAssertEqual(spy.interactorCallCount, 0)
        XCTAssertEqual(spy.observeId, "")
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
        let (sut, spy, scheduler) = makeSUT()
        let expectedError = anyError()
        spy.interactorStub = .error(expectedError)
        
        sut.didSearch("melting")
        scheduler.advanceTo(300)
        
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
    
    func test_didSearch_deliversUsersOnSuccess() {
        let (sut, spy, scheduler) = makeSUT()
        let restaurants = [makeRestaurant(name: "melting")]
        
        spy.interactorStub = .just(restaurants)
        
        sut.didSearch("melting")
        scheduler.advanceTo(300)
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showRestaurants(restaurants.map { RestaurantItemViewModel(from: $0) })
        ])
    }
    
    func test_didSearch_debouncesFastConsecutiveQueries() {
        let (sut, spy, scheduler) = makeSUT()
        
        sut.didSearch("mel")
        scheduler.advanceTo(100)
        XCTAssertEqual(spy.interactorCallCount, 0)
        
        sut.didSearch("melti")
        scheduler.advanceTo(200)
        XCTAssertEqual(spy.interactorCallCount, 0)
        
        sut.didSearch("melting")
        scheduler.advanceTo(299)
        XCTAssertEqual(spy.interactorCallCount, 0)
        
        scheduler.advanceTo(500)
        
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.interactorMessage.count, 1)
        XCTAssertEqual(spy.interactorMessage.last, .request(query: "melting"))
    }
    
    func test_didSearch_doesNotDuplicateSameSearch() {
        let (sut, spy, scheduler) = makeSUT()

        sut.didSearch("melting")
        scheduler.advanceTo(300)
        XCTAssertEqual(spy.interactorCallCount, 1)
        
        sut.didSearch("melting")
        scheduler.advanceTo(600)
        XCTAssertEqual(spy.interactorCallCount, 1)
        
        XCTAssertEqual(spy.interactorMessage.count, 1)
    }
    
    func test_didSearch_doesNotRequestOnWhiteSpace() {
        let (sut, spy, scheduler) = makeSUT()

        sut.didSearch(" ")
        scheduler.advanceTo(600)
        XCTAssertEqual(spy.interactorCallCount, 0)
    }
    
    func test_didSearch_requestsInitialDataWhenUserClearsSearchQuery() {
        let (sut, spy, scheduler) = makeSUT()
        
        sut.didSearch("melting")
        scheduler.advanceTo(300)
        XCTAssertEqual(spy.interactorCallCount, 1)
        XCTAssertEqual(spy.interactorMessage.last, .request(query: "melting"))
        
        sut.didSearch("")
        scheduler.advanceTo(600)
        
        XCTAssertEqual(spy.interactorCallCount, 2)
        XCTAssertEqual(spy.interactorMessage.last, .request(query: ""))
    }
    
    func test_didSelectRestaurant_deliversIdWhenTrigger() {
        let (sut, spy, _) = makeSUT()
        let id = UUID().uuidString
        
        sut.didSelectRestaurant(id: id)
        
        XCTAssertEqual(spy.observeId, id)
    }
    
    func test_view_shouldHaveBeenDeallocated() {
        let (sut, _, _) = makeSUT()
        
        do {
            let tempView = ViewSpy()
            sut.view = tempView
            XCTAssertNotNil(sut.view)
        }

        XCTAssertNil(sut.view)
    }
    
    //MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RestaurantListPresenter, spy: ViewSpy, scheduler: TestScheduler) {
        let scheduler = TestScheduler(initialClock: 0)
        let sut = RestaurantListPresenter(scheduler: scheduler, dueTime: .seconds(300))
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
        var observeId = ""
        static func createModule() -> UIViewController {  UIViewController() }
        
        func navigateToDetail(view: (any RestaurantListViewProtocol)?, id: String) {
            observeId = id
        }
        
    }

}
