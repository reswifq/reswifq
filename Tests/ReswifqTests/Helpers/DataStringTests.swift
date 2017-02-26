//
//  DataStringTests.swift
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
@testable import Reswifq

class DataStringTests: XCTestCase {

    static let allTests = [
        ("testDataToString", testDataToString)
    ]

    func testDataToString() throws {

        let data: Data? = "Test string".data(using: .utf8)
        let string = try data?.string(using: .utf8)

        XCTAssertEqual(string, "Test string")
    }

    func testInvalidDataString() {

        let data = Data(bytes: [0xf0, 0x28, 0x8c, 0xbc])

        XCTAssertThrowsError(try data.string(using: .utf8), "stringConversionError") { error in
            XCTAssertEqual(error as? Data.ConversionError, Data.ConversionError.stringConversionError)
        }
    }
}
