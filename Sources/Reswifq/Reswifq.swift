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

    private enum Queue {
        static let pending = "pending"
        static let processing = "processing"
    }

    public func enqueue(_ job: Job) throws {

        let encodedJob = try JobBox(job).data().string(using: .utf8)

        try self.client.lpush(Queue.pending, values: [encodedJob])
    }

    public func dequeue(wait: Bool = true) throws -> (identifier: JobID, job: Job) {

        let encodedJob = try self.client.brpoplpush(source: Queue.pending, destination: Queue.processing)

        let jobBox = try JobBox(data: encodedJob.data(using: .utf8))

        // TODO: Check timestamp etc etc

        guard let jobType = self.jobMap[jobBox.type] else {
            fatalError() // TODO: Proper error
        }

        let job = try jobType.init(data: jobBox.job)

        return (identifier: encodedJob, job: job)
    }

    public func complete(_ identifier: JobID) throws {
        try self.client.lrem(Queue.processing, value: identifier, count: -1)
    }
}
