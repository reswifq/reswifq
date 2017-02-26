//
//  Job.swift
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

public protocol Job: DataEncodable, DataDecodable {

    /**
     The type of the job.

     This is used during the deserialization to instruct the queue about what type of job it has to instantiate.

     A default implementation is provided that returns the type's name.
     For example, a class named `MyJob`:
     
     ```
     class MyJob: Job {

     }
     ```

     Will have a default type equal to: `MyJob`.

     - Attention: This value must match the key specified in the `Queue`'s `jobMap`, otherwise the job won't be deserialized correctly.
     */
    static var type: String { get }

    /**
     The body of the job.

     A worker execute the job calling this method.
     Throw an error to indicate that the job failed.
     */
    func perform() throws
}

public extension Job {

    static var type: String {
        return String(describing: self)
    }
}
