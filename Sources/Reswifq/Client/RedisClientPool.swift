//
//  RedisClientPool.swift
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
import Pool

// MARK: - RedisClientPool

/**
 A `RedisClientPool` provides a pool of `RedisClient`s.

 It is important to notice that a `RedisClientPool` is a `RedisClient` itself, meaning that it can be transparently used as a `Queue`'s client.
 
 In fact, this is the recommended usage, but it is also mandatory when running a multi-threaded worker process.
 
 - Attention: Sharing a Redis connection between multiple threads must be avoided, and it's not supported in any way. A `RedisClientPool` must be use instead.
 */
public final class RedisClientPool: Pool<RedisClient> {

    public func execute(_ command: String, arguments: [String]? = nil) throws -> RedisClientResponse {
        let client = try self.draw()

        // Make sure we return the client to the pool, also in case of error
        defer { self.release(client) }

        return try client.execute(command, arguments: arguments)
    }
}
