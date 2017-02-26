//
//  RedisClient.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 23/02/2017.
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
import Pool

public protocol RedisClient {

    func lpush(_ key: String, value: String) throws

    func rpoplpush(source: String, destination: String) throws -> String?

    func brpoplpush(source: String, destination: String) throws -> String

    func lrem(_ list: String, value: String, count: Int) throws
}

public final class RedisClientPool: Pool<RedisClient> {

    fileprivate func execute(_ perform: (RedisClient) throws -> Void) throws {

        let client = try self.draw()

        defer { self.release(client) }

        try perform(client)
    }
}

extension RedisClientPool: RedisClient {

    public func lpush(_ key: String, value: String) throws {

        try self.execute { client in
            try client.lpush(key, value: value)
        }
    }

    public func rpoplpush(source: String, destination: String) throws -> String? {

        var response: String?

        try self.execute { client in
            response = try client.rpoplpush(source: source, destination: destination)
        }

        return response
    }

    public func brpoplpush(source: String, destination: String) throws -> String {

        var response: String!

        try self.execute { client in
            response = try client.brpoplpush(source: source, destination: destination)
        }

        return response
    }

    public func lrem(_ list: String, value: String, count: Int) throws {

        try self.execute { client in
            try client.lrem(list, value: value, count: count)
        }
    }
}
