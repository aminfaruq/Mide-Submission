//
//  RestaurantListRouter.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import UIKit
import RestaurantCore
import FactoryKit


public final class RestaurantListRouter: RestaurantListRouterProtocol {
    public static func createModule(loader: RestaurantListLoader) -> UIViewController {
        let view = RestaurantListViewController()
        let presenter = RestaurantListPresenter()
        let interactor = RestaurantListInteractor(loader: loader)
        let router = RestaurantListRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        
        return view
    }
    
    public func navigateToDetail(view: (any RestaurantListViewProtocol)?, id: String) {
        
    }
    
}
