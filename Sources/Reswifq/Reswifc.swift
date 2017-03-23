//
//  Reswifc.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 24/02/2017.
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

public protocol ReswifcProcess {

    var interval: UInt32 { get }

    func process()
}

/**
 Clock process that manages the repeated execution of individual processes.
 Each process will run in its own thread, at the interval it specifies.
 */
public final class Reswifc {

    // MARK: Initialization

    public init(processes: [ReswifcProcess]) {
        self.processes = processes
    }

    // MARK: Setting and Getting Attributes

    public let processes: [ReswifcProcess]

    // MARK: Processing

    private let group = DispatchGroup()

    private let dispatchQueue = DispatchQueue(label: "com.reswifq.Reswifc", attributes: .concurrent)

    private var isCancelled: Bool = false

    /**
     Starts the clock processing and wait indefinitely.
     */
    public func run() {

        for process in processes {

            self.group.enter()

            self.dispatchQueue.async {

                while !self.isCancelled {
                    process.process()
                    sleep(process.interval)
                }

                self.group.leave()
            }
        }

        self.group.wait()
    }

    /**
     Stops the clock processing. This is useful for testing purposes, but probably doesn't have any real case use other than that.
     */
    public func stop(waitUntilAllProcessesAreFinished: Bool = false) {

        self.isCancelled = true

        if waitUntilAllProcessesAreFinished {
            self.group.wait()
        }
    }
}

// MARK: - Expired Jobs Monitor

extension Reswifc {

    public final class Monitor: ReswifcProcess {

        // MARK: Initialization

        public init(queue: Reswifq, interval: UInt32 = 300, maxRetryAttempts: Int64 = 5) {
            self.queue = queue
            self.interval = interval
            self.maxRetryAttempts = max(1, maxRetryAttempts)
        }

        // MARK: Setting and Getting Attributes

        /// The source queue of the clock process.
        public let queue: Reswifq

        /**
         Defines how often, in seconds, the clock process have to check for expired jobs.
         */
        public let interval: UInt32

        /**
         The maximum number of retry attempts for an expired job.
         The minimum value is capped to 1.
         */
        public let maxRetryAttempts: Int64
        
        // MARK: Processing
        
        public func process() {

            do {
                let jobIDs = try self.queue.processingJobs()

                print("[Reswifc.Monitor] Analyzing \(jobIDs.count) jobs in the processing queue.")

                var expired = 0
                var failed = 0
                var processing = 0

                for jobID in jobIDs {

                    do {
                        guard try self.queue.retryAttempts(for: jobID) < self.maxRetryAttempts else {
                            print("[Reswifc.Monitor] Removing job from the processing queue: \(jobID)")
                            try self.queue.complete(jobID)
                            failed += 1
                            continue
                        }

                        if try self.queue.retryJobIfExpired(jobID) {
                            print("[Reswifc.Monitor] Retry job: \(jobID)")
                            expired += 1
                        } else {
                            processing += 1
                        }

                    } catch let error {
                        print("[Reswifc.Monitor] Error while retrying job: \(error.localizedDescription)")
                    }
                }

                print("[Reswifc.Monitor] Jobs analysis completed. Found \(processing) processing, \(expired) expired and \(failed) failed.")
                
            } catch let error {
                print("[Reswifc.Monitor] Error while retrieving processing jobs: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Delayed Jobs Scheduler

extension Reswifc {

    public final class Scheduler: ReswifcProcess {

        // MARK: Initialization

        public init(queue: Reswifq, interval: UInt32 = 60) {
            self.queue = queue
            self.interval = interval
        }

        // MARK: Setting and Getting Attributes

        /// The source queue of the clock process.
        public let queue: Reswifq

        /**
         Defines how often, in seconds, the clock process have to check for expired jobs.
         */
        public let interval: UInt32

        // MARK: Processing

        public func process() {

            do {
                try self.queue.enqueueOverdueJobs()
            } catch let error {
                print("[Reswifc.Scheduler] Error while enqueuing delayed jobs: \(error.localizedDescription)")
            }
        }
    }
}
