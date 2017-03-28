//
//  MemQueueTests.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 28/02/2017.
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
@testable import Reswifq

class MemQueueTests: XCTestCase {

    static let allTests = [
        ("testDequeue", testDequeue),
        ("testDequeuePriority", testDequeuePriority),
        ("testDequeueDelayed", testDequeueDelayed)
    ]
    
    func testDequeue() throws {

        let queue = MemQueue()

        let job1 = MockJob(value: "job1")
        let job2 = MockJob(value: "job2")

        try queue.enqueue(job1, priority: .medium)
        try queue.enqueue(job2, priority: .medium)

        let persistedJob = try queue.dequeue()

        XCTAssertEqual(persistedJob?.job as? MockJob, job1)
    }

    func testDequeuePriority() throws {

        let queue = MemQueue()

        let job1 = MockJob(value: "job1")
        let job2 = MockJob(value: "job2")

        try queue.enqueue(job1, priority: .medium)
        try queue.enqueue(job2, priority: .high)

        let persistedJob = try queue.dequeue()

        XCTAssertEqual(persistedJob?.job as? MockJob, job2)
    }

    func testDequeueDelayed() throws {

        let queue = MemQueue()

        let job1 = MockJob(value: "job1")
        let job2 = MockJob(value: "job2")
        let job3 = MockJob(value: "job3")
        let job4 = MockJob(value: "job4")
        let job5 = MockJob(value: "job5")
        let job6 = MockJob(value: "job6")

        try queue.enqueue(job1, priority: .medium)
        try queue.enqueue(job2, priority: .medium, scheduleAt: Date(timeIntervalSince1970: 0.0))
        try queue.enqueue(job3, priority: .high, scheduleAt: Date(timeIntervalSince1970: 10.0))
        try queue.enqueue(job4, priority: .medium, scheduleAt: Date(timeIntervalSince1970: 10.0))
        try queue.enqueue(job5, priority: .high, scheduleAt: Date(timeIntervalSinceNow: 3600.0))
        try queue.enqueue(job6, priority: .high)

        XCTAssertEqual(try queue.dequeue()?.job as? MockJob, job3)
        XCTAssertEqual(try queue.dequeue()?.job as? MockJob, job2)
        XCTAssertEqual(try queue.dequeue()?.job as? MockJob, job4)
        XCTAssertEqual(try queue.dequeue()?.job as? MockJob, job6)
        XCTAssertEqual(try queue.dequeue()?.job as? MockJob, job1)
        XCTAssertNil(try queue.dequeue())
    }
}

extension MemQueueTests {

    struct MockJob: Job, Equatable {

        let value: String

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
