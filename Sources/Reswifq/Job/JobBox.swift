//
//  JobBox.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 26/02/2017.
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

struct JobBox {

    // MARK: Initializer

    public init(_ job: Job, priority: QueuePriority = .medium) throws {
        self.identifier = UUID().uuidString
        self.createdAt = Date()
        self.type = Swift.type(of: job).type
        self.timeToLive = job.timeToLive
        self.priority = priority
        self.job = try job.data()
    }

    // MARK: Setting and Getting Attributes

    public let identifier: String

    public let createdAt: Date

    public let type: String

    public let timeToLive: TimeInterval

    public let priority: QueuePriority

    public let job: Data
}

extension JobBox: DataEncodable, DataDecodable {

    // Encoding Keys

    enum EncodingKey {
        static let identifier = "identifier"
        static let createdAt = "createdAt"
        static let type = "type"
        static let timeToLive = "timeToLive"
        static let priority = "priority"
        static let job = "job"
    }

    // MARK: DataDecodable

    init(data: Data) throws {

        let object = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = object as? Dictionary<String, Any> else {
            throw DataDecodableError.invalidData(data)
        }

        guard let identifier = dictionary[EncodingKey.identifier] as? String,
            let createdAt = JobBox.decodeTimeInterval(dictionary[EncodingKey.createdAt]),
            let type = dictionary[EncodingKey.type] as? String,
            let timeToLive = JobBox.decodeTimeInterval(dictionary[EncodingKey.timeToLive]),
            let priority = JobBox.decodeQueuePriority(dictionary[EncodingKey.priority]),
            let job = dictionary[EncodingKey.job] as? String
            else {
                throw DataDecodableError.invalidData(data)
        }

        self.identifier = identifier
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.type = type
        self.timeToLive = timeToLive
        self.priority = priority
        self.job = try job.data(using: .utf8)
    }

    private static func decodeQueuePriority(_ value: Any?) -> QueuePriority? {

        guard let value = value as? String else {
            return nil
        }

        return QueuePriority(rawValue: value)
    }

    private static func decodeTimeInterval(_ value: Any?) -> TimeInterval? {

        guard let value = value else {
            return nil
        }

        switch value {
        case let value as TimeInterval:
            return value
        case let value as Int:
            return TimeInterval(value)
        case let value as Int8:
            return TimeInterval(value)
        case let value as Int16:
            return TimeInterval(value)
        case let value as Int32:
            return TimeInterval(value)
        case let value as Int64:
            return TimeInterval(value)
        case let value as UInt:
            return TimeInterval(value)
        case let value as UInt8:
            return TimeInterval(value)
        case let value as UInt16:
            return TimeInterval(value)
        case let value as UInt32:
            return TimeInterval(value)
        case let value as UInt64:
            return TimeInterval(value)
        default:
            return nil
        }
    }

    // MARK: DataEncodable

    func data() throws -> Data {

        let object: [String: Any] = [
            EncodingKey.identifier: self.identifier,
            EncodingKey.createdAt: self.createdAt.timeIntervalSince1970,
            EncodingKey.type: self.type,
            EncodingKey.timeToLive: self.timeToLive,
            EncodingKey.priority: self.priority.rawValue,
            EncodingKey.job: try self.job.string(using: .utf8)
        ]
        
        return try JSONSerialization.data(withJSONObject: object)
    }
}
