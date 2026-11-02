//
//  RestaurantDetailPresenterTests.swift
//  RestaurantApp
//
//  Created by Amin faruq on 02/11/26.
//

import XCTest
import RxSwift
import RestaurantApp
import RestaurantCore

final class RestaurantDetailPresenter : RestaurantDetailPresenterProtocol {
    weak var view: RestaurantDetailViewProtocol?
    
    var interactor: RestaurantDetailInteractorProtocol?
    
    private let disposeBag = DisposeBag()
    
    private let id: String
    
    public init(id: String) {
        self.id = id
    }
    
    func viewDidLoad() {
        requestDetail()
        checkFavoriteStatus()
    }
    
    func didAddReview(_ review: AddReviewBody) {}
    
    func didDismissPopup() {}
    
    func didPullToRefresh() {}
    
    func didTapFavoriteButton() {}
    
    private func checkFavoriteStatus() {
        interactor?.isFavorite(id: id)
            .subscribe(
                onSuccess: { [weak self] isFavorite in
                    guard let self = self else { return }
                    view?.setFavoriteStatus(isFavorite: isFavorite)
                },
                onFailure: { [weak self] _ in
                    guard let self = self else { return }
                    view?.setFavoriteStatus(isFavorite: false)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func requestDetail() {
        view?.showLoading()
        interactor?.loadRestaurantDetail(id: id)
            .subscribe(
                onSuccess: { [weak self] result in
                    guard let self = self else { return }
                    view?.hideLoading()
                    view?.showRestaurant(RestaurantDetailItemViewModel(from: result))
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

final class RestaurantDetailPresenterTests: XCTestCase {
    
    func test_init_doesNotMessageViewOrInteractorUponCreation() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.interactorCallCount, 0)
        XCTAssertEqual(spy.interactorMessages, [])
        XCTAssertEqual(spy.viewMessages, [])
    }

    func test_viewDidLoad_requestsRestaurantDetailAndFavoriteStatus() {
        let (sut, spy) = makeSUT()
        
        sut.viewDidLoad()
        
        XCTAssertEqual(spy.interactorCallCount, 2)
    }

    func test_viewDidLoad_deliversErrorOnDetailFailure() {
        let (sut, spy) = makeSUT()
        let expectedError = anyError()
        spy.loadRestaurantDetailStub = .error(expectedError)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showError(expectedError.localizedDescription)
        ])
    }

    func test_viewDidLoad_deliversRestaurantDetailOnDetailSuccess() {
        let (sut, spy) = makeSUT()
        let expectedResult = makeDetailRestaurant(name: "melting")
        spy.loadRestaurantDetailStub = .just(expectedResult)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(spy.viewMessages, [
            .showLoading,
            .hideLoading,
            .showRestaurant(RestaurantDetailItemViewModel(from: expectedResult))
        ])
    }
    
    func test_viewDidLoad_setsFavoriteStatusTrueWhenRestaurantIsFavorited() {
        let id = anyId()
        let (sut, spy) = makeSUT(id: id)
        spy.isFavoriteStub = .just(true)
        
        sut.viewDidLoad()
        
        XCTAssertTrue(spy.viewMessages.contains(.setFavoriteStatus(isFavorite: true)))
        XCTAssertEqual(spy.interactorMessages, [
            .requestRestaurant(id: id),
            .isFavorite(id: id)
        ])
    }

    func test_viewDidLoad_setsFavoriteStatusFalseWhenRestaurantIsNotFavorited() {
        let id = anyId()
        let (sut, spy) = makeSUT(id: id)
        spy.isFavoriteStub = .just(false)
        
        sut.viewDidLoad()
        
        XCTAssertTrue(spy.viewMessages.contains(.setFavoriteStatus(isFavorite: false)))
        XCTAssertEqual(spy.interactorMessages, [
            .requestRestaurant(id: id),
            .isFavorite(id: id)
        ])
    }

    func test_viewDidLoad_ignoresFavoriteStatusErrorOnFailure() {
        let id = anyId()
        let expectedError = anyError()
        let (sut, spy) = makeSUT(id: id)
        spy.isFavoriteStub = .error(expectedError)
        
        sut.viewDidLoad()
        
        XCTAssertTrue(spy.viewMessages.contains(.setFavoriteStatus(isFavorite: false)))
    }
    
    func test_didTapFavoriteButton_requestsToggleFavoriteOnInteractor() {}

    func test_didTapFavoriteButton_updatesFavoriteStatusOnSuccess() {}

    func test_didTapFavoriteButton_deliversErrorOnFailure() {}
    
    func test_didAddReview_requestsAddReviewOnInteractor() {}

    func test_didAddReview_deliversErrorOnFailure() {}

    func test_didAddReview_reloadsDetailOnSuccess() {}
    
    func test_didPullToRefresh_reloadsRestaurantDetailAndFavoriteStatus() {}
    
    func test_didDismissPopup_handlesPopupDismissal() {}
    
    func test_view_shouldHaveBeenDeallocated() {
        let (sut, _) = makeSUT()
        
        do {
            let tempView = ViewSpy()
            sut.view = tempView
            XCTAssertNotNil(sut.view)
        }
        
        XCTAssertNil(sut.view)
    }
    
    //MARK: - Helpers
    private func makeSUT(
        id: String = anyId(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RestaurantDetailPresenter,
        spy: ViewSpy
    ) {
        let sut = RestaurantDetailPresenter(id: id)
        let spy = ViewSpy()
        
        sut.view = spy
        sut.interactor = spy
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)
        
        return (sut, spy)
    }
    
    private class ViewSpy: RestaurantDetailViewProtocol, RestaurantDetailInteractorProtocol {
        
        // MARK: View
        enum ViewMessage: Equatable {
            case showLoading
            case hideLoading
            case showRestaurant(_ restaurant: RestaurantDetailItemViewModel)
            case showMenus(_ results: [String])
            case showError(_ message: String)
            case showPopup
            case setFavoriteStatus(isFavorite: Bool)
        }
        
        private(set) var viewMessages = [ViewMessage]()
        
        func showLoading() {
            viewMessages.append(.showLoading)
        }
        
        func hideLoading() {
            viewMessages.append(.hideLoading)
        }
        
        func showRestaurant(_ restaurant: RestaurantDetailItemViewModel) {
            viewMessages.append(.showRestaurant(restaurant))
        }
        
        func showMenus(_ results: [String]) {
            viewMessages.append(.showMenus(results))
        }
        
        func showError(_ message: String) {
            viewMessages.append(.showError(message))
        }
        
        func showPopup() {
            viewMessages.append(.showPopup)
        }
        
        func setFavoriteStatus(isFavorite: Bool) {
            viewMessages.append(.setFavoriteStatus(isFavorite: isFavorite))
        }
        
        // MARK: Interactor
        enum InteractorMessage: Equatable {
            case requestRestaurant(id: String)
            case requestAddReview(body: AddReviewBody)
            case isFavorite(id: String)
            case toggleFavorite(restaurant: RestaurantEntity)
        }
        
        var interactorCallCount: Int {
            interactorMessages.count
        }
        
        private(set) var interactorMessages = [InteractorMessage]()
        
        var loadRestaurantDetailStub: Single<RestaurantDetailEntity> = .never()
        var addReviewStub: Completable = .never()
        
        var isFavoriteStub: Single<Bool> = .never()
        var toggleFavoriteStub: Single<Bool> = .never()
        
        func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
            interactorMessages.append(.requestRestaurant(id: id))
            return loadRestaurantDetailStub
        }
        
        func addReview(body: AddReviewBody) -> Completable {
            interactorMessages.append(.requestAddReview(body: body))
            return addReviewStub
        }
        
        func isFavorite(id: String) -> Single<Bool> {
            interactorMessages.append(.isFavorite(id: id))
            return isFavoriteStub
        }
        
        func toggleFavorite(restaurant: RestaurantEntity) -> Single<Bool> {
            interactorMessages.append(.toggleFavorite(restaurant: restaurant))
            return toggleFavoriteStub
        }
    }
}
