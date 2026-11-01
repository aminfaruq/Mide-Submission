//
//  RestaurantListProtocols.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import UIKit
import RxSwift
import RestaurantCore

// MARK: - View
public protocol RestaurantListViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func showRestaurants(_ restaurants: [RestaurantItemViewModel])
    func showError(_ message: String)
}

// MARK: - Interactor
public protocol RestaurantListInteractorProtocol: AnyObject {
    func loadRestaurants(query: String) -> Single<[RestaurantEntity]>
}

public extension RestaurantListInteractorProtocol {
    func loadRestaurants(query: String = "") -> Single<[RestaurantEntity]> {
        loadRestaurants(query: query)
    }
}

// MARK: - Presenter
public protocol RestaurantListPresenterProtocol: AnyObject {
    var view: RestaurantListViewProtocol? { get set }
    var interactor: RestaurantListInteractorProtocol? { get set }
    var router: RestaurantListRouterProtocol? { get set }
    
    func viewDidLoad()
    func didPullToRefresh()
    func didSearch(_ query: String)
    func didSelectRestaurant(id: String)
}

// MARK: - Router
public protocol RestaurantListRouterProtocol: AnyObject {
    static func createModule(loader: RestaurantListLoader) -> UIViewController
    
    func navigateToDetail(view: RestaurantListViewProtocol?, id: String)
}

