//
//  Reswifq.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 21/02/2017.
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

import Foundation

public enum ReswifqError: Error {
    case unknownJobType(String)
}

// MARK: - Reswifq

public final class Reswifq: Queue {

    // MARK: Initialization

    public required init(client: RedisClient) {
        self.client = client
    }

    // MARK: Setting and Getting Attributes

    public let client: RedisClient

    public var jobMap = [String: Job.Type]()

    /**
     Maximum time a job can stay in the processing queue.
     After exceeding this interval, the job would be re-enqueued by `reswifc`.
     */
    public var timeToLive: TimeInterval = 3600.0 // 1 hour

    // MARK: Queue

    /// Priority not supported at the moment
    /// See https://github.com/antirez/redis/issues/1785
    public func enqueue(_ job: Job, priority: QueuePriority = .medium) throws {

        let encodedJob = try JobBox(job).data().string(using: .utf8)

        //try self.client.lpush(RedisKey(.queuePending(priority)).value, values: encodedJob)
        try self.client.lpush(RedisKey(.queuePending(.medium)).value, values: encodedJob)
    }

    public func dequeue() throws -> PersistedJob? {

        guard let encodedJob = try self.client.rpoplpush(
            source: RedisKey(.queuePending(.medium)).value,
            destination: RedisKey(.queueProcessing).value
        ) else {
            return nil
        }

        let persistedJob = try self.persistedJob(with: encodedJob)

        self.setLock(for: persistedJob.identifier)

        return persistedJob
    }

    public func bdequeue() throws -> PersistedJob {

        let encodedJob = try self.client.brpoplpush(
            source: RedisKey(.queuePending(.medium)).value,
            destination: RedisKey(.queueProcessing).value
        )

        let persistedJob = try self.persistedJob(with: encodedJob)

        self.setLock(for: persistedJob.identifier)

        return persistedJob
    }

    public func complete(_ identifier: JobID) throws {

        try self.client.lrem(RedisKey(.queueProcessing).value, value: identifier, count: -1)
    }
}

// MARK: - Queue Helpers

extension Reswifq {

    fileprivate func persistedJob(with encodedJob: String) throws -> PersistedJob {

        let jobBox = try JobBox(data: encodedJob.data(using: .utf8))

        guard let jobType = self.jobMap[jobBox.type] else {
            throw ReswifqError.unknownJobType(jobBox.type)
        }

        let job = try jobType.init(data: jobBox.job)

        return (identifier: encodedJob, job: job)
    }

    fileprivate func setLock(for identifier: JobID) {

        try? self.client.setex(RedisKey(.lock(identifier)).value, timeout: self.timeToLive)
    }
}

// MARK: RedisKey

extension Reswifq {

    fileprivate struct RedisKey {

        // MARK: Initialization

        public init(_ key: RedisKey.Key) {
            self.init(key.components)
        }

        public init(_ components: String...) {
            self.init(components)
        }

        public init(_ components: [String]) {
            self.value = components.joined(separator: ":")
        }

        // MARK: Attributes

        public let value: String
    }
}

extension Reswifq.RedisKey {

    fileprivate enum Key {

        case queuePending(QueuePriority)
        case queueProcessing

        case lock(String)

        case info
    }
}

extension Reswifq.RedisKey.Key {

    var components: [String] {

        switch self {

        case .queuePending(let priority):
            return ["queue", "pending", priority.rawValue]

        case .queueProcessing:
            return ["queue", "processing"]

        case .lock(let value):
            return ["lock", value]

        case .info:
            return ["info"]
        }
    }
}
