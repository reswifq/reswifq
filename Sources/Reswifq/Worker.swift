//
//  Worker.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 22/02/2017.
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

public class Worker {

    // MARK: Initialization

    public init(queue: Queue, maxConcurrentJobs: UInt = 10, averagePollingInterval: UInt32 = 0) {
        self.queue = queue
        self.maxConcurrentJobs = maxConcurrentJobs
        self.averagePollingInterval = averagePollingInterval
    }

    // MARK: Setting and Getting Attributes

    /// The source queue of the worker process.
    public var queue: Queue

    /**
     Defines the average amount of time which a worker's thread
     has to sleep in between jobs processing.

     When a value of `0` is specified, the worker `dequeue` the jobs
     setting the wait parameter to false, asking the queue to block the thread
     and return only when a job is available.
    */
    public let averagePollingInterval: UInt32

    /// The maximum number of concurrent jobs this worker process can handle at the same time
    public let maxConcurrentJobs: UInt

    // MARK: Processing

    private let _queue = DispatchQueue(label: "com.reswifq.BaseWorker", attributes: .concurrent)

    /**
     Starts the worker processing and wait indefinitely.
     */
    public func run() {

        let threadShouldWait = self.averagePollingInterval == 0

        let group = DispatchGroup()
        group.enter()

        for index in 0..<self.maxConcurrentJobs {

            print("Spawing worker thread: \(index + 1)")

            self._queue.async {

                while true {
                    do {
                        print("Worker[t:\(index + 1)]: Dequeuing job...")
                        let ref = try self.queue.dequeue(wait: threadShouldWait)
                        print("Worker[t:\(index + 1)]: Dequeued: \(ref.identifier)")
                        try ref.job.perform()
                        print("Worker[t:\(index + 1)]: Performed: \(ref.identifier)")
                        try self.queue.complete(ref.identifier)
                        print("Worker[t:\(index + 1)]: Completed: \(ref.identifier)")
                    } catch let error {
                        // Log the error
                        print("Error: \(error.localizedDescription)")
                    }

                    if threadShouldWait {
                        let waitInterval = random(self.averagePollingInterval)
                        print("Worker[t:\(index + 1)]: Waiting: \(waitInterval)")

                        wait(seconds: waitInterval)
                    }
                }
            }
        }

        group.wait()
    }
}
