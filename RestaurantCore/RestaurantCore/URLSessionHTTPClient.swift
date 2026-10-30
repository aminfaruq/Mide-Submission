//
//  URLSessionHTTPClient.swift
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

public final class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL) -> Single<HTTPClient.Result> {
        return execute(request: URLRequest(url: url))
    }
    
    public func post(to url: URL, body: HTTPBody?) -> Single<HTTPClient.Result> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let body {
            request.httpBody = body.data
            switch body.contentType {
                case .json:
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        return execute(request: request)
    }
    
    private func execute(request: URLRequest) -> Single<HTTPClient.Result> {
        return Single.create { [session] single in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    single(.failure(error))
                    return
                }
                
                guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                    single(.failure(UnexpectedValuesRepresentation()))
                    return
                }
                
                single(.success((data, httpResponse)))
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    public struct UnexpectedValuesRepresentation: Error {}
}
