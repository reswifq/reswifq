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
        ("testExecute", testExecute),
        ("testLPUSH", testLPUSH),
        ("testLPUSHError", testLPUSHError),
        ("testRPOPLPUSH", testRPOPLPUSH),
        ("testRPOPLPUSHWithEmptyList", testRPOPLPUSHWithEmptyList),
        ("testRPOPLPUSHError", testRPOPLPUSHError),
        ("testBRPOPLPUSH", testBRPOPLPUSH),
        ("testBRPOPLPUSHError", testBRPOPLPUSHError),
        ("testSETEX", testSETEX),
        ("testSETEXError", testSETEXError),
        ("testLREM", testLREM),
        ("testLREMError", testLREMError),
        ("testZADD", testZADD),
        ("testZADDError", testZADDError)
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

        _ = try client.execute("TEST", arguments: "arg1", "arg2")

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testLPUSH() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "LPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "a")
            XCTAssertEqual(arguments?[2], "b")
            XCTAssertEqual(arguments?[3], "c")
            expectation.fulfill()

            return RedisClientResponse.integer(3)
        }

        let count = try client.lpush("test", values: "a", "b", "c")

        self.waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(count, 3)
    }

    func testLPUSHError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            expectation.fulfill()

            return RedisClientResponse.null
        }

        XCTAssertThrowsError(try client.lpush("test", values: "a", "b", "c"), "lpush") { error in
            XCTAssertTrue(error is RedisClientError)
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testRPOPLPUSH() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "RPOPLPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "anotherTest")
            expectation.fulfill()

            return RedisClientResponse.string("a")
        }

        let item = try client.rpoplpush(source: "test", destination: "anotherTest")

        self.waitForExpectations(timeout: 4.0, handler: nil)
        
        XCTAssertEqual(item, "a")
    }

    func testRPOPLPUSHWithEmptyList() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "RPOPLPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "anotherTest")
            expectation.fulfill()

            return RedisClientResponse.null
        }

        let item = try client.rpoplpush(source: "test", destination: "anotherTest")

        self.waitForExpectations(timeout: 4.0, handler: nil)
        
        XCTAssertNil(item)
    }

    func testRPOPLPUSHError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "RPOPLPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "anotherTest")
            expectation.fulfill()

            return RedisClientResponse.error("error")
        }

        XCTAssertThrowsError(try client.rpoplpush(source: "test", destination: "anotherTest"), "rpoplpush") { error in
            XCTAssertTrue(error is RedisClientError)
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testBRPOPLPUSH() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "BRPOPLPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "anotherTest")
            expectation.fulfill()

            return RedisClientResponse.string("a")
        }

        let item = try client.brpoplpush(source: "test", destination: "anotherTest")

        self.waitForExpectations(timeout: 4.0, handler: nil)
        
        XCTAssertEqual(item, "a")
    }

    func testBRPOPLPUSHError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "execute")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "BRPOPLPUSH")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "anotherTest")
            expectation.fulfill()

            return RedisClientResponse.null
        }

        XCTAssertThrowsError(try client.brpoplpush(source: "test", destination: "anotherTest"), "brpoplpush") { error in
            XCTAssertTrue(error is RedisClientError)
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testSETEX() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "setex")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "SETEX")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "60.0")
            XCTAssertEqual(arguments?[2], "a")
            expectation.fulfill()

            return RedisClientResponse.status(.ok)
        }

        try client.setex("test", timeout: 60.0, value: "a")

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testSETEXError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "setex")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "SETEX")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "60.0")
            XCTAssertEqual(arguments?[2], "a")
            expectation.fulfill()

            return RedisClientResponse.error("error")
        }

        XCTAssertThrowsError(try client.setex("test", timeout: 60.0, value: "a"), "setex") { error in
            XCTAssertTrue(error is RedisClientError)
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testLREM() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "lrem")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "LREM")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "-5")
            XCTAssertEqual(arguments?[2], "a")
            expectation.fulfill()

            return RedisClientResponse.integer(1)
        }

        try client.lrem("test", value: "a", count: -5)

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testLREMError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "lrem")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "LREM")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "-5")
            XCTAssertEqual(arguments?[2], "a")
            expectation.fulfill()

            return RedisClientResponse.error("error")
        }

        XCTAssertThrowsError(try client.lrem("test", value: "a", count: -5), "lrem") { error in
            XCTAssertTrue(error is RedisClientError)
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testZADD() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "zadd")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "ZADD")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "1.0")
            XCTAssertEqual(arguments?[2], "a")
            XCTAssertEqual(arguments?[3], "2.0")
            XCTAssertEqual(arguments?[4], "b")
            expectation.fulfill()

            return RedisClientResponse.integer(2)
        }

        try client.zadd("test", values: [(score: 1, member: "a"), (score: 2, member: "b")])

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testZADDError() throws {

        let client = MockClient()

        let expectation = self.expectation(description: "zadd")

        client.execute = { command, arguments in
            XCTAssertEqual(command, "ZADD")
            XCTAssertEqual(arguments?[0], "test")
            XCTAssertEqual(arguments?[1], "1.0")
            XCTAssertEqual(arguments?[2], "a")
            XCTAssertEqual(arguments?[3], "2.0")
            XCTAssertEqual(arguments?[4], "b")
            expectation.fulfill()

            return RedisClientResponse.error("error")
        }

        XCTAssertThrowsError(try client.zadd("test", values: [(score: 1, member: "a"), (score: 2, member: "b")]), "lrem") { error in
            XCTAssertTrue(error is RedisClientError)
        }

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
