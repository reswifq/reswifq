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

public final class Reswifq: Queue {

    // MARK: Initialization

    public required init(client: RedisClient) {
        self.client = client
    }

    // MARK: Setting and Getting Attributes

    public let client: RedisClient

    public var jobMap = [String: Job.Type]()

    // MARK: Queue

    public func enqueue(_ job: Job, priority: QueuePriority = .medium) throws {

        let encodedJob = try JobBox(job).data().string(using: .utf8)

        // TODO: Replace this with the proper method name
        _ = try self.client.execute(
            "LPUSH",
            arguments: RedisKey(.queuePending(priority)).value, encodedJob
        )
    }

    public func dequeue() throws -> PersistedJob? {

        var encodedJob: String!

        //if wait {
            //encodedJob = try self.client.brpoplpush(source: Queue.pending, destination: Queue.processing)
        //} else {
            /*
            guard let result = try self.client.rpoplpush(source: Queue.pending, destination: Queue.processing) else {
                throw QueueError.queueIsEmpty
            }

            encodedJob = result*/
        //}

        let jobBox = try JobBox(data: encodedJob.data(using: .utf8))

        // TODO: Check timestamp etc etc

        guard let jobType = self.jobMap[jobBox.type] else {
            fatalError() // TODO: Proper error
        }

        let job = try jobType.init(data: jobBox.job)

        return (identifier: encodedJob, job: job)
    }

    public func bdequeue() throws -> PersistedJob {
        fatalError()
    }

    public func complete(_ identifier: JobID) throws {

        //let a: String = Key.queue(.pending(.high)).name

        //try self.client.lrem(Queue.processing, value: identifier, count: -1)
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
        case queueDelayed

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

        case .queueDelayed:
            return ["queue", "delayed"]

        case .info:
            return ["info"]
        }
    }
}
