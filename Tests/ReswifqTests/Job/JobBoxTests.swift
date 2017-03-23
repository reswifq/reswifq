//
//  JobBoxTests.swift
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

class JobBoxTests: XCTestCase {

    static let allTests = [
        ("testInitialization", testInitialization),
        ("testEncode", testEncode),
        ("testDecode", testDecode),
        ("testDecodeInvalidData", testDecodeInvalidData),
        ("testDecodeInvalidDataWithMissingField", testDecodeInvalidDataWithMissingField)
    ]

    func testInitialization() throws {

        let job = MockJob()
        let box = try JobBox(job)

        XCTAssertNotNil(box.identifier)
        XCTAssertEqualWithAccuracy(box.createdAt.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2.0)
        XCTAssertEqual(box.type, "MockJob")
        XCTAssertEqual(box.timeToLive, 3600.0)
        XCTAssertEqual(box.job, Data())
    }

    func testEncode() throws {

        let job = MockJob()
        let box = try JobBox(job)

        let data = try box.data()

        let dictionaryData: [String: Any] = [
            JobBox.EncodingKey.identifier: box.identifier,
            JobBox.EncodingKey.createdAt: box.createdAt.timeIntervalSince1970,
            JobBox.EncodingKey.type: box.type,
            JobBox.EncodingKey.timeToLive: box.timeToLive,
            JobBox.EncodingKey.priority: box.priority.rawValue,
            JobBox.EncodingKey.job: try job.data().string(using: .utf8)
        ]

        let rawData = try JSONSerialization.data(withJSONObject: dictionaryData)

        XCTAssertEqual(data, rawData)
    }

    func testDecode() throws {

        let job = MockJob()
        let box = try JobBox(job)
        let boxData = try box.data()

        let decodedBox = try JobBox(data: boxData)

        XCTAssertEqual(decodedBox.identifier, box.identifier)
        XCTAssertEqualWithAccuracy(decodedBox.createdAt.timeIntervalSince1970, box.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(decodedBox.type, box.type)
        XCTAssertEqual(decodedBox.timeToLive, box.timeToLive)
        XCTAssertEqual(decodedBox.job, box.job)
    }

    func testDecodeInvalidData() throws {

        let dictionaryData: [[String: Any]] = [["test": "test"]]

        let rawData = try JSONSerialization.data(withJSONObject: dictionaryData)

        XCTAssertThrowsError(try JobBox(data: rawData), "invalidData") { error in
            XCTAssertEqual(error as? DataDecodableError, DataDecodableError.invalidData(rawData))
        }
    }

    func testDecodeInvalidDataWithMissingField() throws {

        let dictionaryData: [String: Any] = [
            "identifier": "abc123"
        ]

        let rawData = try JSONSerialization.data(withJSONObject: dictionaryData)

        XCTAssertThrowsError(try JobBox(data: rawData), "invalidData") { error in
            XCTAssertEqual(error as? DataDecodableError, DataDecodableError.invalidData(rawData))
        }
    }
}

extension JobBoxTests {

    struct MockJob: Job {

        init() {

        }

        init(data: Data) throws {

        }

        func data() throws -> Data {
            return Data()
        }

        func perform() throws {
            
        }
    }
}
