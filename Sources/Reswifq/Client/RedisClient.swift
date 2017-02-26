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

public protocol RedisClient {

    /**
     Executes the [LPUSH](https://redis.io/commands/lpush) command.

     Insert all the specified values at the head of the list stored at key. If key does not exist, it is created as empty list before performing the push operations. When key holds a value that is not a list, an error is returned.

     It is possible to push multiple elements using a single command call just specifying multiple arguments at the end of the command. Elements are inserted one after the other to the head of the list, from the leftmost element to the rightmost element.

     So for instance the command `LPUSH` mylist `a` `b` `c` will result into a list containing `c` as first element, `b` as second element and `a` as third element.

     - parameter key: The key of the list to add the elements to.
     - parameter values: The values to add to the list.

     - returns: The length of the list after the push operations.
     */
    @discardableResult func lpush(_ key: String, values: [String]) throws -> Int

    /**
     Executes the [RPOPLPUSH](https://redis.io/commands/rpoplpush) command.

     Atomically returns and removes the last element (tail) of the list stored at source, and pushes the element at the first element (head) of the list stored at destination.

     For example: consider source holding the list `a,b,c`, and destination holding the list `x,y,z`. Executing `RPOPLPUSH` results in source holding `a,b` and destination holding `c,x,y,z`.

     If source does not exist, the value `nil` is returned and no operation is performed. 
     If source and destination are the same, the operation is equivalent to removing the last element from the list and pushing it as first element of the list, so it can be considered as a list rotation command.
     
     - parameter source: The source list.
     - parameter destination: The destination list.

     - returns: The element being popped and pushed.
     */
    func rpoplpush(source: String, destination: String) throws -> String?

    /**
     Executes the [BRPOPLPUSH](https://redis.io/commands/brpoplpush) command.

     `BRPOPLPUSH` is the blocking variant of `RPOPLPUSH`. When source contains elements, this command behaves exactly like `RPOPLPUSH`.
     
     When source is empty, Redis will block the connection until another client pushes to it or until timeout is reached. A timeout of zero can be used to block indefinitely.

     See `RPOPLPUSH` for more information.
     
     - parameter source: The source list.
     - parameter destination: The destination list.

     - returns: The element being popped from source and pushed to destination. If timeout is reached, an error is thrown.
     */
    func brpoplpush(source: String, destination: String) throws -> String

    /**
     Executes the [LREM](https://redis.io/commands/lrem) command.

     Removes the first count occurrences of elements equal to value from the list stored at key.
     The count argument influences the operation in the following ways:

     - count > 0: Remove elements equal to value moving from head to tail.
     - count < 0: Remove elements equal to value moving from tail to head.
     - count = 0: Remove all elements equal to value.

     - parameter key: The key of the list to remove the elements from.
     - parameter value: The value to remove from the list.
     - parameter count: The number of elements to remove.

     - returns: The number of removed elements.
     */
    @discardableResult func lrem(_ key: String, value: String, count: Int) throws -> Int
}
