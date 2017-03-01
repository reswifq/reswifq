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

    public init(queue: Queue, maxConcurrentJobs: Int = 10, averagePollingInterval: UInt32 = 0) {
        self.queue = queue
        self.maxConcurrentJobs = max(1, maxConcurrentJobs)
        self.averagePollingInterval = averagePollingInterval
        self.semaphore = DispatchSemaphore(value: maxConcurrentJobs)
    }

    // MARK: Setting and Getting Attributes

    /// The source queue of the worker process.
    public let queue: Queue

    /**
     Defines the average amount of time (in seconds) which a worker's thread
     has to sleep in between jobs processing.

     When a value of `0` is specified, the worker `dequeue`s jobs,
     setting the wait parameter to `true`, asking the queue to block the thread
     and return only when a job is available.
    */
    public let averagePollingInterval: UInt32

    /**
     The maximum number of concurrent jobs this worker process can handle at the same time.
     The minimum value is capped to 1.
     */
    public let maxConcurrentJobs: Int

    // MARK: Processing

    private let dispatchQueue = DispatchQueue(label: "com.reswifq.Worker", attributes: .concurrent)

    private let semaphore: DispatchSemaphore

    /**
     Starts the worker processing and wait indefinitely.
     */
    public func run() {

        while true {

            guard self.semaphore.wait(timeout: .distantFuture) == .success else {
                continue // Not sure if this can ever happen when using distantFuture
            }

            let workItem = self.makeWorkItem {
                if self.averagePollingInterval > 0 {
                    wait(seconds: random(self.averagePollingInterval))
                }

                self.semaphore.signal()
            }

            self.dispatchQueue.async(execute: workItem)
        }
    }

    private func makeWorkItem(_ completion: (() -> Void)? = nil) -> DispatchWorkItem {

        return DispatchWorkItem(block: {

            defer { completion?() }

            do {
                guard let persistedJob = self.averagePollingInterval == 0
                    ? try self.queue.bdequeue()
                    : try self.queue.dequeue()
                    else {
                        return // Nothing to process
                }

                try persistedJob.job.perform()
                try self.queue.complete(persistedJob.identifier)

            } catch let error {
                // Log the error
                print("Error: \(error.localizedDescription)")
            }
        })
    }
}
