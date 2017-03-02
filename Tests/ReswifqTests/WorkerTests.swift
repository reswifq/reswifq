//
//  WorkerTests.swift
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
import Dispatch
import Foundation
@testable import Reswifq

class WorkerTests: XCTestCase {

    static let allTests = [
        ("testSerialProcessing", testSerialProcessing),
        ("testSerialEmptyQueueProcessing", testSerialEmptyQueueProcessing),
        ("testSerialEmptyQueueProcessingWithWaitDequeue", testSerialEmptyQueueProcessingWithWaitDequeue),
        ("testConcurrentProcessing", testConcurrentProcessing),
        ("testConcurrentProcessingWithWaitDequeue", testConcurrentProcessingWithWaitDequeue)
    ]

    func testSerialProcessing() throws {

        let queue = MemQueue()

        let group = try self.enqueue(10, in: queue)

        DispatchQueue(label: "com.reswifq.WorkerTests").async {
            let worker = Worker(queue: queue, maxConcurrentJobs: 1, averagePollingInterval: 0)
            worker.run()
        }

        self.wait(for: group, timeout: 60.0)

        XCTAssertTrue(queue.isEmpty)
    }

    func testSerialEmptyQueueProcessing() throws {

        let queue = MemQueue()

        DispatchQueue(label: "com.reswifq.WorkerTests").async {
            let worker = Worker(queue: queue, maxConcurrentJobs: 1, averagePollingInterval: 1)
            worker.run()
        }

        let group = DispatchGroup()
        let job = self.createJob(with: group)

        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            do {
                try queue.enqueue(job)
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: group, timeout: 60.0)

        XCTAssertTrue(queue.isEmpty)
    }

    func testSerialEmptyQueueProcessingWithWaitDequeue() throws {

        let queue = MemQueue()

        DispatchQueue(label: "com.reswifq.WorkerTests").async {
            let worker = Worker(queue: queue, maxConcurrentJobs: 1, averagePollingInterval: 0)
            worker.run()
        }

        let group = DispatchGroup()
        let job = self.createJob(with: group)

        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            do {
                try queue.enqueue(job)
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: group, timeout: 60.0)

        XCTAssertTrue(queue.isEmpty)
    }

    func testConcurrentProcessing() throws {

        let queue = MemQueue()

        let group = try self.enqueue(100, in: queue)

        DispatchQueue(label: "com.reswifq.WorkerTests").async {
            let worker = Worker(queue: queue, maxConcurrentJobs: 10, averagePollingInterval: 1)
            worker.run()
        }

        self.wait(for: group, timeout: 60.0)

        XCTAssertTrue(queue.isEmpty)
    }

    func testConcurrentProcessingWithWaitDequeue() throws {

        let queue = MemQueue()

        DispatchQueue(label: "com.reswifq.WorkerTests").async {
            let worker = Worker(queue: queue, maxConcurrentJobs: 10, averagePollingInterval: 0)
            worker.run()
        }

        let group = try self.enqueue(1000, in: queue)

        self.wait(for: group, timeout: 60.0)

        XCTAssertTrue(queue.isEmpty)
    }
}

extension WorkerTests {

    fileprivate func enqueue(_ numberOfJobs: Int, in queue: Queue) throws -> DispatchGroup {

        let group = DispatchGroup()

        for _ in 0..<numberOfJobs {
            let job = createJob(with: group)
            try queue.enqueue(job, priority: .medium)
        }

        return group
    }

    fileprivate func wait(for group: DispatchGroup, timeout: TimeInterval) {

        guard group.wait(timeout: .now() + timeout) == .success else {
            XCTFail("Asynchronous wait failed: Exceeded timeout of 60 seconds")

            return
        }
    }

    fileprivate func createJob(with group: DispatchGroup) -> Job {

        group.enter()

        return MockJob() {
            group.leave()
        }
    }

    final class MockJob: Job {

        var _perform: (() -> Void)?

        func perform() throws {
            self._perform?()
        }

        init(_ perform: @escaping (() -> Void)) {
            self._perform = perform
        }

        init(data: Data) throws {
            fatalError()
        }

        func data() throws -> Data {
            fatalError()
        }
    }
}
