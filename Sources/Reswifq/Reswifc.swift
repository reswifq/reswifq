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

/**
 Expired jobs monitor.
 */
public class Reswifc {

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

    private var isCancelled: Bool = false

    /**
     Starts the clock processing and wait indefinitely.
     */
    public func run() {

        self.isCancelled = false

        while !self.isCancelled {

            do {
                let jobIDs = try self.queue.processingJobs()

                print("[Reswifc] Analyzing \(jobIDs.count) jobs in the processing queue.")

                for jobID in jobIDs {

                    do {
                        guard try self.queue.retryAttempts(for: jobID) < self.maxRetryAttempts else {
                            print("[Reswifc] Removing job from the processing queue: \(jobID)")
                            try self.queue.complete(jobID)
                            continue
                        }

                        try self.queue.retryJobIfExpired(jobID)

                    } catch let error {
                        print("[Reswifc] Error while retrying job: \(error.localizedDescription)")
                    }
                }
            } catch let error {
                print("[Reswifc] Error while retrieving processing jobs: \(error.localizedDescription)")
            }
        }
    }

    /**
     Stops the clock processing. This is useful for testing purposes, but probably doesn't have any real case use other than that.
     */
    public func stop() {

        self.isCancelled = true
    }
}
