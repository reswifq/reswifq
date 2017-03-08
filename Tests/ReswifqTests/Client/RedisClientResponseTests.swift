//
//  RedisClientResponseTests.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 08/03/2017.
//  Copyright © 2017 VMLabs Limited. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//

import XCTest
@testable import Reswifq

class RedisClientResponseTests: XCTestCase {

    static let allTests = [
        ("testArray", testArray),
        ("testError", testError),
        ("testInteger", testInteger),
        ("testNull", testNull),
        ("testStatus", testStatus),
        ("testString", testString),
        ]

    func testArray() {
        let response = RedisClientResponse.array([])

        XCTAssertNotNil(response.array)
        XCTAssertTrue(response.array!.isEmpty)
        XCTAssertNil(response.error)
        XCTAssertNil(response.integer)
        XCTAssertFalse(response.isNull)
        XCTAssertNil(response.status)
        XCTAssertNil(response.string)
    }

    func testError() {
        let response = RedisClientResponse.error("test error")

        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error, "test error")
        XCTAssertNil(response.array)
        XCTAssertNil(response.integer)
        XCTAssertFalse(response.isNull)
        XCTAssertNil(response.status)
        XCTAssertNil(response.string)
    }

    func testInteger() {
        let response = RedisClientResponse.integer(1)

        XCTAssertNotNil(response.integer)
        XCTAssertEqual(response.integer, 1)
        XCTAssertNil(response.array)
        XCTAssertNil(response.error)
        XCTAssertFalse(response.isNull)
        XCTAssertNil(response.status)
        XCTAssertNil(response.string)
    }

    func testNull() {
        let response = RedisClientResponse.null

        XCTAssertNil(response.integer)
        XCTAssertNil(response.array)
        XCTAssertNil(response.error)
        XCTAssertTrue(response.isNull)
        XCTAssertNil(response.status)
        XCTAssertNil(response.string)
    }

    func testStatus() {
        let response = RedisClientResponse.status(.ok)

        XCTAssertNotNil(response.status)
        XCTAssertEqual(response.status, .ok)
        XCTAssertNil(response.array)
        XCTAssertNil(response.error)
        XCTAssertFalse(response.isNull)
        XCTAssertNil(response.integer)
        XCTAssertNil(response.string)
    }

    func testString() {
        let response = RedisClientResponse.string("test")

        XCTAssertNotNil(response.string)
        XCTAssertEqual(response.string, "test")
        XCTAssertNil(response.array)
        XCTAssertNil(response.error)
        XCTAssertFalse(response.isNull)
        XCTAssertNil(response.integer)
        XCTAssertNil(response.status)
    }
}
