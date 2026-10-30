//
//  RemoteRestaurantListLoader.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import Foundation
import RxSwift

public struct HTTPBody: Equatable {
    public enum ContentType: Equatable {
        case json
    }
    
    public let data: Data
    public let contentType: ContentType
    
    public init(data: Data, contentType: ContentType) {
        self.data = data
        self.contentType = contentType
    }
}

public protocol HTTPClient {
    typealias Result = (Data, HTTPURLResponse)
    
    func get(from url: URL) -> Single<Result>
    func post(to url: URL, body: HTTPBody?) -> Single<Result>
}

public enum NetworkError: Swift.Error, LocalizedError, Equatable {
    case connectivity
    case invalidData
    case decodeError
}

public protocol RestaurantListLoader {
    func loadRestaurants(query: String) -> Single<[RestaurantEntity]>
}

public final class RemoteRestaurantListLoader: RestaurantListLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func loadRestaurants(query: String = "") -> Single<[RestaurantEntity]> {
        let requestedURL = url
            .appending(path: "search")
            .appending(queryItems: [
                URLQueryItem(name: "q", value: query)
            ])
        return client.get(from: requestedURL)
            .catch({ _ in
                return .error(NetworkError.connectivity)
            })
            .flatMap { (data, response) in
                
                switch response.statusCode {
                    case 200:
                        guard let root = try? JSONDecoder().decode(RootDTO.self, from: data) else {
                            return .error(NetworkError.decodeError)
                        }
                        return .just(root.restaurants.map { $0.toModel() })
                    default:
                        return .error(NetworkError.invalidData)
                }
            }
    }
    
    private struct RootDTO: Decodable {
        let restaurants: [RemoteRestaurantDTO]
    }
    
    private struct RemoteRestaurantDTO: Decodable {
        private let id: String
        private let name: String
        private let description: String
        private let pictureId: String
        private let city: String
        private let rating: Double
        
        func toModel() -> RestaurantEntity {
            .init(
                id: id,
                name: name,
                description: description,
                pictureId: pictureId,
                city: city,
                rating: rating
            )
        }
    }
}
