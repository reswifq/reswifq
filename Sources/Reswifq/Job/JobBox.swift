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

    public init(_ job: Job) throws {
        self.identifier = UUID().uuidString
        self.createdAt = Date()
        self.type = type(of: job).type
        self.job = try job.data()
    }

    // MARK: Setting and Getting Attributes

    public let identifier: String

    public let createdAt: Date

    public let type: String

    public let job: Data
}

extension JobBox: DataEncodable, DataDecodable {

    // Encoding Keys

    enum EncodingKey {
        static let identifier = "identifier"
        static let createdAt = "createdAt"
        static let type = "type"
        static let job = "job"
    }

    // MARK: DataDecodable

    init(data: Data) throws {

        let object = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = object as? Dictionary<String, Any> else {
            throw DataDecodableError.invalidData(data)
        }

        guard let identifier = dictionary[EncodingKey.identifier] as? String,
            let createdAt = dictionary[EncodingKey.createdAt] as? TimeInterval,
            let type = dictionary[EncodingKey.type] as? String,
            let job = dictionary[EncodingKey.job] as? String
            else {
                throw DataDecodableError.invalidData(data)
        }

        self.identifier = identifier
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.type = type
        self.job = try job.data(using: .utf8)
    }

    // MARK: DataEncodable

    func data() throws -> Data {

        let object: [String: Any] = [
            EncodingKey.identifier: self.identifier,
            EncodingKey.createdAt: self.createdAt.timeIntervalSince1970,
            EncodingKey.type: self.type,
            EncodingKey.job: try self.job.string(using: .utf8)
        ]
        
        return try JSONSerialization.data(withJSONObject: object)
    }
}
