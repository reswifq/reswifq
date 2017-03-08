//
//  RedisClientResponse.swift
//  Reswifq
//
//  Created by Valerio Mazzeo on 08/03/2017.
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

public enum RedisClientResponse {

    /// An array response from a Redis server. The value is an array of the individual
    /// responses that made up the array response.
    case array([RedisClientResponse])

    /// An error from the Redis server.
    case error(String)

    /// An Integer value returned from the Redis server.
    case integer(Int64)

    /// A Null response returned from the Redis server.
    case null

    /// A status response returned from the Redis server.
    case status(Status)

    /// A Bulk string response returned from the Redis server.
    case string(String)
}

public extension RedisClientResponse {

    public enum Status: String {
        case ok = "OK"
        case queued = "QUEUED"
    }
}

public extension RedisClientResponse {

    var array: [RedisClientResponse]? {
        switch self {
        case .array(let value):
            return value
        default:
            return nil
        }
    }

    var error: String? {
        switch self {
        case .error(let value):
            return value
        default:
            return nil
        }
    }

    var integer: Int64? {
        switch self {
        case .integer(let value):
            return value
        default:
            return nil
        }
    }

    var isNull: Bool {
        switch self {
        case .null:
            return true
        default:
            return false
        }
    }

    var status: Status? {
        switch self {
        case .status(let value):
            return value
        default:
            return nil
        }
    }

    var string: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}
