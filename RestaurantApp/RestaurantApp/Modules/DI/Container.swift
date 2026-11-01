//
//  Container.swift
//  RestaurantApp
//
//  Created by Amin faruq on 01/11/26.
//

import FactoryKit
import Foundation
import RestaurantCore

extension Container {
    
    // MARK: - Low Level Module
    var baseImageURL: Factory<URL> {
        self { URL(string: "https://restaurant-api.dicoding.dev/images/medium")! }
    }
    
    var baseURL: Factory<URL> {
        self { URL(string: "https://restaurant-api.dicoding.dev")! }
    }
    
    var cacheStore: Factory<CacheStore> {
        self { RealmCacheStore() }
    }
    
    var favoriteStore: Factory<FavoriteStore> {
        self { RealmFavoriteStore() }
    }
    
    var client: Factory<HTTPClient> {
        self { URLSessionHTTPClient() }
    }
    
    // MARK: - High Level Module
    /// - Home Injection
    var remoteRestaurantListLoader: Factory<RestaurantListLoader> {
        self { RemoteRestaurantListLoader(url: self.baseURL(), client: self.client()) }
    }
    
    var cacheSaver: Factory<CacheSaver> {
        self { LocalCacheSaver(store: self.cacheStore()) }
    }
    
    var localCacheRestaurantListLoader: Factory<RestaurantListLoader> {
        self { LocalCacheRestaurantListLoader(store: self.cacheStore()) }
    }
    
    var restaurantListLoader: Factory<RestaurantListLoader> {
        self {
            let cachingRemote = RestaurantListLoaderCacheDecorator(decoratee: self.remoteRestaurantListLoader(), cache: self.cacheSaver())
            
            let composite = RestaurantListLoaderWithFallbackComposite(primary: cachingRemote, fallback: self.localCacheRestaurantListLoader())
            
            return composite
        }
    }
    
    /// - Favorite Injection
    var localFavoriteRestaurantListLoader: Factory<RestaurantListLoader> {
        self { LocalFavoriteRestaurantListLoader(store: self.favoriteStore()) }
    }
}
