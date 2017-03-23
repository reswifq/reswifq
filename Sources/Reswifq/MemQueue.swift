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

    private var jobs = [JobID: (job: Job, priority: QueuePriority, scheduleAt: Date?)]()

    private var delayed = [JobID]()

    private var pendingHigh = [JobID]()

    private var pendingMedium = [JobID]()

    private var pendingLow = [JobID]()

    // MARK: Queue

    private func queueStorage(for priority: QueuePriority, isDelayed: Bool, queue: (inout [JobID]) -> Void) {

        switch (priority, isDelayed) {

        // Delayed
        case (_, true):
            queue(&self.delayed)

        // Pending
        case (.high, false):
            queue(&self.pendingHigh)
        case (.medium, false):
            queue(&self.pendingMedium)
        case (.low, false):
            queue(&self.pendingLow)
        }
    }

    public func enqueue(_ job: Job, priority: QueuePriority = .medium, scheduleAt: Date? = nil) throws {

        self.queue.async {

            let identifier = UUID().uuidString

            self.jobs[identifier] = (job: job, priority: priority, scheduleAt: scheduleAt)

            self.queueStorage(for: priority, isDelayed: scheduleAt != nil) { $0.append(identifier) }
        }
    }

    private func _dequeue() -> JobID? {

        let now = Date()

        let delayed = self.delayed.filter { identifier in

            guard let scheduledAt = self.jobs[identifier]?.scheduleAt else { return false }
            return scheduledAt <= now

        }.sorted {

            guard let lhs = self.jobs[$0] else { return false }
            guard let rhs = self.jobs[$1] else { return false }

            switch (lhs.priority, rhs.priority) {
            case (.high, .medium), (.high, .low):
                return true
            case (.low, .medium), (.low, .high):
                return false
            default:
                return false
            }
        }

        if let delayedJobID = delayed.first {
            if let index = self.delayed.index(of: delayedJobID) {
                self.delayed.remove(at: index)
            }
            return delayedJobID

        } else if !self.pendingHigh.isEmpty {
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

            guard let jobBox = self.jobs[jobID] else {
                throw MemQueueError.dataIntegrityFailure
            }

            return (identifier: jobID, job: jobBox.job)
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
