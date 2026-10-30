//
//  HTTPClientSpy.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import RestaurantCore
import Foundation
import RxSwift

class HTTPClientSpy: HTTPClient {
    enum Message: Equatable {
        case get(URL)
        case post(URL, body: HTTPBody?)
    }
    
    private(set) var messages = [Message]()
    
    var requestedURL: [URL] {
        messages.map { data in
            switch data {
                case let .get(url):
                    return url
                case let .post(url, _):
                    return url
            }
        }
    }
    
    var stub: Single<HTTPClient.Result> = .never()
    
    func get(from url: URL) -> Single<HTTPClient.Result> {
        messages.append(.get(url))
        return stub
    }
    
    func post(to url: URL, body: HTTPBody?) -> Single<HTTPClient.Result> {
        messages.append(.post(url, body: body))
        return stub
    }
}
