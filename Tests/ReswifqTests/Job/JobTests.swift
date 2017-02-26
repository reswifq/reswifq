//
//  JobTests.swift
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

import XCTest
import Foundation
@testable import Reswifq

class JobTests: XCTestCase {

    static let allTests = [
        ("testDefaultType", testDefaultType)
    ]

    func testDefaultType() {
        XCTAssertEqual(MockJob.type, "MockJob")
    }
}

extension JobTests {

    struct MockJob: Job {

        init(data: Data) throws {

        }

        func data() throws -> Data {
            return Data()
        }

        func perform() throws {
            
        }
    }
}
