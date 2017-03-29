//
//  ReswifqKituraTests.swift
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
import KituraRedisClient
@testable import Reswifq

class ReswifqKituraTests: XCTestCase {

    static let allTests = [
        ("testPerformance", testPerformance),
        ("testEnqueue", testEnqueue),
        ("testDequeue", testDequeue),
        ("testDequeueEmpty", testDequeueEmpty),
        ("testDequeueUnmappedJob", testDequeueUnmappedJob),
        ("testBdequeue", testBdequeue),
        ("testPendingJobs", testPendingJobs),
        ("testDelayedJobs", testDelayedJobs),
        ("testOverdueJobs", testOverdueJobs),
        ("testEnqueueOverdueJobs", testEnqueueOverdueJobs),
        ("testProcessingJobs", testProcessingJobs),
        ("testComplete", testComplete),
        ("testIsJobExpired", testIsJobExpired),
        ("testRetryJobIfExpired", testRetryJobIfExpired),
        ("testRetryJobIfExpiredShouldSkipIfJobHasNotExpired", testRetryJobIfExpiredShouldSkipIfJobHasNotExpired),
        ("testRetryAttempts", testRetryAttempts),
        ("testRetryAttemptsForNotExistingJob", testRetryAttemptsForNotExistingJob),
        ("testRedisKeyWithComponents", testRedisKeyWithComponents),
        ("testRedisKeyComponents", testRedisKeyComponents)
    ]

    var queue: Reswifq!

    override func setUp() {
        super.setUp()

        self.queue = self.makeQueue()
    }

    override func tearDown() {
        self.queue = nil
        super.tearDown()
    }

    func testPerformance() throws {

        self.measure {
            try! self.queue.enqueue(MockJob(value: "test"))
            _ = try! self.queue.dequeue()
        }
    }

    func testEnqueue() throws {

        try self.queue.enqueue(MockJob(value: "test"))

        XCTAssertEqual(try self.queue.pendingJobs().count, 1)
    }

    func testDequeue() throws {

        let job1 = MockJob(value: "test1")
        let job2 = MockJob(value: "test2")
        let job3 = MockJob(value: "test3")

        try self.queue.enqueue(job1)
        try self.queue.enqueue(job2)
        try self.queue.enqueue(job3)

        let persistedJob1 = try self.queue.dequeue()
        let persistedJob2 = try self.queue.dequeue()
        let persistedJob3 = try self.queue.dequeue()
        let persistedJob4 = try self.queue.dequeue()

        XCTAssertNotNil(persistedJob1)
        XCTAssertNotNil(persistedJob2)
        XCTAssertNotNil(persistedJob3)
        XCTAssertNil(persistedJob4)

        XCTAssertEqual(persistedJob1?.job as? MockJob, job1)
        XCTAssertEqual(persistedJob2?.job as? MockJob, job2)
        XCTAssertEqual(persistedJob3?.job as? MockJob, job3)

        // Make sure the expiration lock has been set,
        // expired would be true if no lock is present
        XCTAssertFalse(try self.queue.isJobExpired(persistedJob1!.identifier))
        XCTAssertFalse(try self.queue.isJobExpired(persistedJob2!.identifier))
        XCTAssertFalse(try self.queue.isJobExpired(persistedJob3!.identifier))
    }

    func testDequeueEmpty() throws {

        XCTAssertNil(try self.queue.dequeue())
    }

    func testDequeueUnmappedJob() throws {

        try self.queue.enqueue(MockJob(value: "test1"))

        self.queue.jobMap.removeAll()

        XCTAssertThrowsError(try self.queue.dequeue(), "dequeue") { error in
            switch error as? ReswifqError {
            case .some(.unknownJobType("MockJob")):
                break
            default:
                XCTFail()
            }
        }
    }

    func testBdequeue() throws {

        let job = MockJob(value: "test")

        DispatchQueue(label: "com.reswifq.ReswifqTests").async {
            // Using another queue / client to enqueue the request,
            // otherwise the connection would be blocked by the dequeuing operation
            try? self.makeQueue().enqueue(job)
        }

        let persistedJob = try self.queue.bdequeue()

        XCTAssertEqual(persistedJob.job as? MockJob, job)
        XCTAssertFalse(try self.queue.isJobExpired(persistedJob.identifier))
    }

    func testPendingJobs() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"))
        try self.queue.enqueue(MockJob(value: "test3"))

        XCTAssertEqual(try self.queue.pendingJobs().count, 3)
    }

    func testProcessingJobs() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"))
        try self.queue.enqueue(MockJob(value: "test3"))

        _ = try self.queue.dequeue()
        _ = try self.queue.dequeue()
        _ = try self.queue.dequeue()

        XCTAssertTrue((try self.queue.pendingJobs()).isEmpty)
        XCTAssertEqual(try self.queue.processingJobs().count, 3)
    }

    func testDelayedJobs() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"), scheduleAt: Date())
        try self.queue.enqueue(MockJob(value: "test3"), scheduleAt: Date())

        _ = try self.queue.dequeue()
        _ = try self.queue.dequeue()
        _ = try self.queue.dequeue()

        XCTAssertEqual(try self.queue.delayedJobs().count, 2)
    }

    func testOverdueJobs() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"), scheduleAt: Date(timeIntervalSinceNow: 3600.0))
        try self.queue.enqueue(MockJob(value: "test3"), scheduleAt: Date(timeIntervalSince1970: 10.0))

        XCTAssertEqual(try self.queue.overdueJobs().count, 1)
    }

    func testEnqueueOverdueJobs() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        try self.queue.enqueue(MockJob(value: "test2"), scheduleAt: Date(timeIntervalSinceNow: 3600.0))
        try self.queue.enqueue(MockJob(value: "test3"), scheduleAt: Date(timeIntervalSince1970: 10.0))

        try self.queue.enqueueOverdueJobs()

        XCTAssertEqual(try self.queue.delayedJobs().count, 1)
        XCTAssertEqual(try self.queue.overdueJobs().count, 0)
        XCTAssertEqual(try self.queue.pendingJobs().count, 2)
    }

    func testComplete() throws {
        try self.queue.enqueue(MockJob(value: "test1", timeToLive: 1.0))
        var persistedJob = try self.queue.dequeue()

        sleep(2)

        try self.queue.retryJobIfExpired(persistedJob!.identifier)
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 1)

        persistedJob = try self.queue.dequeue()

        try self.queue.complete(persistedJob!.identifier)

        XCTAssertEqual(try self.queue.processingJobs().count, 0)
        XCTAssertTrue(try self.queue.isJobExpired(persistedJob!.identifier))
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 0)
    }

    func testIsJobExpired() throws {

        try self.queue.enqueue(MockJob(value: "test1", timeToLive: 0.0))
        let persistedJob = try self.queue.dequeue()

        XCTAssertTrue(try self.queue.isJobExpired(persistedJob!.identifier))
    }

    func testRetryJobIfExpired() throws {

        try self.queue.enqueue(MockJob(value: "test1", timeToLive: 0.0))
        let persistedJob = try self.queue.dequeue()
        try self.queue.retryJobIfExpired(persistedJob!.identifier)

        XCTAssertEqual(try self.queue.pendingJobs().count, 1)
        XCTAssertEqual(try self.queue.processingJobs().count, 0)
        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 1)
    }

    func testRetryJobIfExpiredShouldSkipIfJobHasNotExpired() throws {

        try self.queue.enqueue(MockJob(value: "test1"))
        let persistedJob = try self.queue.dequeue()
        try self.queue.retryJobIfExpired(persistedJob!.identifier)

        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 0)
    }

    func testRetryAttempts() throws {

        try self.queue.enqueue(MockJob(value: "test1", timeToLive: 0.0))
        let persistedJob = try self.queue.dequeue()
        try self.queue.retryJobIfExpired(persistedJob!.identifier)

        XCTAssertEqual(try self.queue.retryAttempts(for: persistedJob!.identifier), 1)
    }

    func testRetryAttemptsForNotExistingJob() throws {

        XCTAssertEqual(try self.queue.retryAttempts(for: "1234"), 0)
    }

    func testRedisKeyWithComponents() {

        XCTAssertEqual(Reswifq.RedisKey("component1", "component2").value, "component1:component2")
    }

    func testRedisKeyComponents() {

        XCTAssertEqual(Reswifq.RedisKey.Key.queuePending(.medium).components, ["queue", "pending", "medium"])
        XCTAssertEqual(Reswifq.RedisKey.Key.queueProcessing.components, ["queue", "processing"])
        XCTAssertEqual(Reswifq.RedisKey.Key.queueDelayed.components, ["queue", "delayed"])
        XCTAssertEqual(Reswifq.RedisKey.Key.lock("test").components, ["lock", "test"])
        XCTAssertEqual(Reswifq.RedisKey.Key.retry("test").components, ["retry", "test"])
    }
}

extension ReswifqKituraTests {

    struct MockJob: Job, Equatable {

        let value: String

        let timeToLive: TimeInterval

        init(value: String, timeToLive: TimeInterval = 3600.0) {
            self.value = value
            self.timeToLive = timeToLive
        }

        init(data: Data) throws {
            let dataString = try data.string(using: .utf8)
            let components = dataString.components(separatedBy: ":")

            self.value = components[0]
            self.timeToLive = TimeInterval(components[1])!
        }

        func data() throws -> Data {
            return try "\(self.value):\(self.timeToLive)".data(using: .utf8)
        }

        func perform() throws {
            
        }

        public static func ==(lhs: MockJob, rhs: MockJob) -> Bool {
            return lhs.value == rhs.value
        }
    }

    fileprivate func makeQueue() -> Reswifq {

        let client = Redis()
        client.connect(host: "localhost", port: 6379) { _ in }
        client.flushdb { _, _ in }

        let queue = Reswifq(client: client)
        queue.jobMap[String(describing: MockJob.self)] = MockJob.self

        return queue
    }
}
