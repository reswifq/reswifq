//
//  MemQueue.swift
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

import Foundation
import Dispatch

enum MemQueueError: Error {
    case dataIntegrityFailure
}

/**
 Simple, thread safe, in memory queue.
 It doesn't implement the Reliable Queue Pattern.
 */
public class MemQueue: Queue {

    // MARK: Setting and Getting Attributes

    var isEmpty: Bool {
        return self.pendingHigh.isEmpty && self.pendingMedium.isEmpty && self.pendingLow.isEmpty
    }

    // MARK: Concurrency Management

    private let queue = DispatchQueue(label: "com.reswifq.MemQueue")

    // MARK: Queue Storage

    private var jobs = [JobID: Job]()

    private var pendingHigh = [JobID]()

    private var pendingMedium = [JobID]()

    private var pendingLow = [JobID]()

    // MARK: Queue

    private func queueStorage(for priority: QueuePriority, queue: (inout [JobID]) -> Void) {
        switch priority {
        case .high:
            queue(&self.pendingHigh)
        case .medium:
            queue(&self.pendingMedium)
        case .low:
            queue(&self.pendingLow)
        }
    }

    public func enqueue(_ job: Job, priority: QueuePriority = .medium) throws {

        self.queue.async {

            let identifier = UUID().uuidString
            self.jobs[identifier] = job

            self.queueStorage(for: priority) { $0.append(identifier) }
        }
    }

    private func _dequeue() -> JobID? {
        if !self.pendingHigh.isEmpty {
            return self.pendingHigh.removeFirst()
        } else if !self.pendingMedium.isEmpty {
            return self.pendingMedium.removeFirst()
        } else if !self.pendingLow.isEmpty {
            return self.pendingLow.removeFirst()
        } else {
            return nil
        }
    }

    public func dequeue() throws -> PersistedJob? {

        return try self.queue.sync {

            guard let jobID = self._dequeue() else {
                return nil
            }

            guard let job = self.jobs[jobID] else {
                throw MemQueueError.dataIntegrityFailure
            }

            return (identifier: jobID, job: job)
        }
    }

    public func bdequeue() throws -> PersistedJob {

        while true {

            guard let job = try self.dequeue() else {
                continue
            }

            return job
        }
    }

    public func complete(_ job: JobID) throws {
        self.queue.async {
            self.jobs[job] = nil
        }
    }
}
