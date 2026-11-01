//
//  RestaurantListPresenter.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import RxSwift
import Foundation

public final class RestaurantListPresenter: RestaurantListPresenterProtocol {
    
    public weak var view: RestaurantListViewProtocol?
    public var interactor: RestaurantListInteractorProtocol?
    public var router: RestaurantListRouterProtocol?
    
    private var searchSubject = PublishSubject<String>()
        
    private let disposeBag = DisposeBag()
    
    private let scheduler: SchedulerType
    private let dueTime: RxTimeInterval
    
    public init(scheduler: SchedulerType = MainScheduler.instance, dueTime: RxTimeInterval = .milliseconds(300)) {
        self.scheduler = scheduler
        self.dueTime = dueTime
        setupSearchPipeline()
    }
    
    public func viewDidLoad() {
        loadInitialData()
    }
    
    public func didPullToRefresh() {
        loadInitialData()
    }
    
    public func didSearch(_ query: String) {
        searchSubject.onNext(query)
    }
    
    public func didSelectRestaurant(id: String) {
        router?.navigateToDetail(view: view, id: id)
    }
    
    private func loadInitialData() {
        executeSearch()
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
    
    nonisolated deinit {}
}
