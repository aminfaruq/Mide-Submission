//
//  RemoteRestaurantDetailLoader.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RxSwift
import Foundation

public struct AddReviewBody: Hashable {
    public let id: String
    public let name: String
    public let review: String
    
    public init(id: String, name: String, review: String) {
        self.id = id
        self.name = name
        self.review = review
    }
}

public protocol RestaurantDetailLoader {
    func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity>
    func addReview(review: AddReviewBody) -> Completable
}

public final class RemoteRestaurantDetailLoader: RestaurantDetailLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func loadRestaurantDetail(id: String) -> Single<RestaurantDetailEntity> {
        let requestedURL = url
            .appending(path: "detail")
            .appending(path: "\(id)")
        return client.get(from: requestedURL)
            .catch({ _ in
                return .error(NetworkError.connectivity)
            })
            .flatMap { data, response in
                switch response.statusCode {
                    case 200:
                        guard let root = try? JSONDecoder().decode(RootDTO.self, from: data) else {
                            return .error(NetworkError.decodeError)
                        }
                        
                        return .just(root.restaurant.toModel())
                    default:
                        return .error(NetworkError.invalidData)
                }
            }
    }
    
    public func addReview(review: AddReviewBody) -> Completable {
        let requestedURL = url
            .appending(path: "review")
        let body = makeBody(from: review)
        return client.post(to: requestedURL, body: body)
            .catch({ _ in
                return .error(NetworkError.connectivity)
            })
            .flatMapCompletable { _, response in
                switch response.statusCode {
                    case 201:
                        return .empty()
                    default:
                        return .error(NetworkError.invalidData)
                }
            }
    }
}

extension RemoteRestaurantDetailLoader {
    private struct RootDTO: Decodable {
        let restaurant: RemoteRestaurantDTO
    }
    
    private struct RemoteRestaurantDTO: Decodable {
        private let id, name, description, city: String
        private let address, pictureId: String
        private let categories: [CategoryDTO]
        private let menus: MenusDTO
        private let rating: Double
        private let customerReviews: [CustomerReviewDTO]
        
        func toModel() -> RestaurantDetailEntity {
            .init(
                id: id,
                name: name,
                description: description,
                city: city,
                address: address,
                pictureId: pictureId,
                categories: categories.map { $0.toModel() },
                menus: menus.toModel(),
                rating: rating,
                customerReviews: customerReviews.map { $0.toModel() })
        }
    }
    
    private struct CategoryDTO: Decodable {
        private let name: String
        
        func toModel() -> CategoryEntity {
            .init(name: name)
        }
    }
    
    private struct CustomerReviewDTO: Decodable {
        private let name, review, date: String
        
        func toModel() -> CustomerReviewEntity {
            .init(name: name, review: review, date: date)
        }
    }
    
    private struct MenusDTO: Decodable {
        private let foods, drinks: [CategoryDTO]
        
        func toModel() -> MenuEntity {
            .init(foods: foods.map { $0.toModel() }, drinks: drinks.map { $0.toModel() })
        }
    }
    
    private func makeBody(from review: AddReviewBody) -> HTTPBody {
        let requestDTO = AddReviewRequestDTO(id: review.id, name: review.name, review: review.review)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        guard let data = try? encoder.encode(requestDTO) else {
            fatalError(NetworkError.invalidData.localizedDescription)
        }
        
        return HTTPBody(data: data, contentType: .json)
    }
    
    private struct AddReviewRequestDTO: Encodable {
        let id: String
        let name: String
        let review: String
    }
}
