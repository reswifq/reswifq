//
//  Queue.swift
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

public typealias JobID = String

public typealias PersistedJob = (identifier: JobID, job: Job)

public protocol Queue {

    func enqueue(_ job: Job, priority: QueuePriority) throws

    /// Returns the next Job to execute, or `nil` if the queue is empty.
    func dequeue() throws -> PersistedJob?

    /// Must block the execution until a Job is available.
    func bdequeue() throws -> PersistedJob

    func complete(_ job: JobID) throws
}

public enum QueuePriority: String {

    case high = "high"
    case medium = "medium"
    case low = "low"
}
