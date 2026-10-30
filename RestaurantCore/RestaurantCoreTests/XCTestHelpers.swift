//
//  XCTestHelpers.swift
//  RestaurantCore
//
//  Created by Amin faruq on 30/10/26.
//

import XCTest
import Foundation
import RestaurantCore

extension XCTestCase {
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Should have been deallocated. Potential memory leaks", file: file, line: line)
        }
    }
}

func anyError() -> NSError {
    NSError(domain: "an-error", code: -99999)
}

func anyURL() -> URL {
    URL(string: "http://any-url.com")!
}

func makeResponse(
    statusCode code: Int,
    data: Data = Data(),
    headers: [String: String]? = nil
) -> HTTPClient.Result {
    let response = HTTPURLResponse(
        url: anyURL(),
        statusCode: code,
        httpVersion: nil,
        headerFields: headers
    )!
    return (data, response)
}
