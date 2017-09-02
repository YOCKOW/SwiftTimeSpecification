/***************************************************************************************************
 SwiftTimeSpecificationTests.swift
  © 2016-2017 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

// FIXME: These are irresponsible tests below.

import XCTest
@testable import TimeSpecification

class TimeSpecificationTests: XCTestCase {
  func testNormalization() {
    let N1 = TimeSpecification(seconds:0, nanoseconds:1_234_567_890)
    let N2 = TimeSpecification(seconds:-1, nanoseconds:-1_234_567_890)
    
    XCTAssertTrue(N1.seconds == 1 && N1.nanoseconds == 234_567_890, "Normalization Test 1")
    XCTAssertTrue(N2.seconds == -3 && N2.nanoseconds == 765_432_110, "Normalization Test 2")
  }
  
  func testComparison() {
    let C1 = TimeSpecification(seconds:100, nanoseconds:100)
    let C2 = TimeSpecification(seconds: 98, nanoseconds:2_000_000_100)
    let C3 = TimeSpecification(seconds:200, nanoseconds:100)
    let C4 = TimeSpecification(seconds:100, nanoseconds:200)
    XCTAssertEqual(C1, C2, "Comparison Test 1")
    XCTAssertTrue(C2 < C3, "Comparison Test 2")
    XCTAssertTrue(C2 < C4, "Comparison Test 3")
  }
  
  func testIntegerLiteral() {
    let I1: TimeSpecification = 100
    let I2: TimeSpecification = -100
    XCTAssertEqual(I1, TimeSpecification(seconds:100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 1")
    XCTAssertEqual(I2, TimeSpecification(seconds:-100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 2")
  }
  
  func testFloatLiteral() {
    let F1: TimeSpecification = 1.1
    XCTAssertEqual(F1, TimeSpecification(seconds:1, nanoseconds:100_000_000), "ExpressibleByFloatLiteral Test 1")
  }
  
  func testSumAndDifference() {
    let L1 = TimeSpecification(seconds:100, nanoseconds:123_456_789)
    let R1 = TimeSpecification(seconds:100, nanoseconds:987_654_321)
    XCTAssertEqual(L1 + R1, TimeSpecification(seconds:201, nanoseconds:111_111_110), "Sum Test 1")
    XCTAssertEqual(L1 - R1, TimeSpecification(seconds:0, nanoseconds:-864_197_532), "Difference Test 1")

  }

  static var allTests = [
    ("Normalization", testNormalization),
    ("Comparison", testComparison),
    ("ExpressibleByIntegerLiteral", testIntegerLiteral),
    ("ExpressibleByFloatLiteral", testFloatLiteral),
    ("+/-", testSumAndDifference)
  ]
}
