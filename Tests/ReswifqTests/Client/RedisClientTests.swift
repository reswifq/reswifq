//
//  RedisClientTests.swift
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

class RedisClientTests: XCTestCase {

    static let allTests = [
        ("testExecute", testExecute)
    ]

    func testExecute() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "TEST")
            XCTAssertEqual(arguments!, ["arg1", "arg2"])
            expectation.fulfill()

            return RedisClientResponse.null
        }

        _ = try client.execute("TEST", arguments: ["arg1", "arg2"])

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }
}

extension RedisClientTests {

    class MockClient: RedisClient {

        var execute: ((String, [String]?) throws -> RedisClientResponse)?

        func execute(_ command: String, arguments: [String]?) throws -> RedisClientResponse {

            return try self.execute?(command, arguments) ?? RedisClientResponse.null
        }
    }
}
