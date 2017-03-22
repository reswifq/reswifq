//
//  ReswifcTests.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 22/03/2017.
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
import Foundation
import Dispatch
import SwiftRedis
import RedisClient
@testable import Reswifq

class ReswifcTests: XCTestCase {

    static let allTests = [
        ("testRetry", testRetry),
        ("testMaxRetryAttempts", testMaxRetryAttempts)
    ]

    var queue: Reswifq!

    override func setUp() {
        super.setUp()

        let client = Redis()
        client.connect(host: "localhost", port: 6379) { _ in }
        client.flushdb { _, _ in }

        self.queue = Reswifq(client: client)
        self.queue.jobMap[String(describing: MockJob.self)] = MockJob.self
    }

    override func tearDown() {
        self.queue = nil
        super.tearDown()
    }

    func testRetry() throws {

        let reswifc = Reswifc(queue: self.queue, interval: 1, maxRetryAttempts: 2)

        DispatchQueue(label: "com.reswifq.ReswifcTests").async {
            reswifc.run()
        }

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"))
        try self.queue.enqueue(MockJob(value: "test3"))
        XCTAssertEqual(try self.queue.pendingJobs().count, 3)

        let persistedJob = try self.queue.dequeue()
        XCTAssertEqual(try self.queue.pendingJobs().count, 2)

        sleep(2)
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 1)
        XCTAssertEqual(try self.queue.pendingJobs().count, 3)

        reswifc.stop()
    }

    func testMaxRetryAttempts() throws {

        let reswifc = Reswifc(queue: self.queue, interval: 1, maxRetryAttempts: 1)

        DispatchQueue(label: "com.reswifq.ReswifcTests").async {
            reswifc.run()
        }

        try self.queue.enqueue(MockJob(value: "test1"))
        XCTAssertEqual(try self.queue.pendingJobs().count, 1)

        let persistedJob = try self.queue.dequeue()
        XCTAssertEqual(try self.queue.pendingJobs().count, 0)

        sleep(2)
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 1)
        XCTAssertEqual(try self.queue.pendingJobs().count, 1)

        _ = try self.queue.dequeue()
        XCTAssertEqual(try self.queue.pendingJobs().count, 0)

        sleep(2)
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 0)
        XCTAssertEqual(try self.queue.pendingJobs().count, 0)
        XCTAssertEqual(try self.queue.processingJobs().count, 0)

        reswifc.stop()
    }
}

extension ReswifcTests {

    struct MockJob: Job, Equatable {

        let value: String

        var timeToLive: TimeInterval {
            return 0.0
        }

        init(value: String) {
            self.value = value
        }

        init(data: Data) throws {
            self.value = try data.string(using: .utf8)
        }

        func data() throws -> Data {
            return try self.value.data(using: .utf8)
        }

        func perform() throws {

        }

        public static func ==(lhs: MockJob, rhs: MockJob) -> Bool {
            return lhs.value == rhs.value
        }
    }
}
