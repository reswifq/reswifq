//
//  sleepTests.swift
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
import Dispatch
@testable import Reswifq

class SleepTests: XCTestCase {

    static let allTests = [
        ("testWait", testWait)
    ]

    func testWait() {

        let expectation = self.expectation(description: "wait")

        let startDate = Date()

        DispatchQueue.global().async {
            sleep(seconds: 2)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)

        let waitInterval = Date().timeIntervalSince(startDate)

        XCTAssertEqualWithAccuracy(waitInterval, 2.0, accuracy: 0.5)
    }
}
