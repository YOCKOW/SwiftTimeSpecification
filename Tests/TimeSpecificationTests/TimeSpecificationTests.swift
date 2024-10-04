/***************************************************************************************************
 SwiftTimeSpecificationTests.swift
  © 2016-2020 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

import XCTest
@testable import TimeSpecification

import Foundation

#if swift(>=6) && canImport(Testing)
import Testing

@Suite struct TimeSpecificationTests {
  @Test func normalization() {
    let N1 = TimeSpecification(seconds:0, nanoseconds:1_234_567_890)
    let N2 = TimeSpecification(seconds:-1, nanoseconds:-1_234_567_890)

    #expect(N1.seconds == 1 && N1.nanoseconds == 234_567_890, "Normalization Test 1")
    #expect(N2.seconds == -3 && N2.nanoseconds == 765_432_110, "Normalization Test 2")
  }

  @Test func codable() throws {
    let spec = TimeSpecification(seconds: 123, nanoseconds: 456_789)
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let encoded = try encoder.encode(spec)
    let encodedString = try #require(String(data: encoded, encoding: .utf8))
    #expect(encodedString == #"{"nanoseconds":456789,"seconds":123}"#)

    let decoded = try JSONDecoder().decode(TimeSpecification.self, from: encoded)
    #expect(decoded == spec)
  }

  @Test func comparison() {
    let C1 = TimeSpecification(seconds:100, nanoseconds:100)
    let C2 = TimeSpecification(seconds: 98, nanoseconds:2_000_000_100)
    let C3 = TimeSpecification(seconds:200, nanoseconds:100)
    let C4 = TimeSpecification(seconds:100, nanoseconds:200)
    #expect(C1 == C2, "Comparison Test 1")
    #expect(C2 < C3, "Comparison Test 2")
    #expect(C2 < C4, "Comparison Test 3")
  }

  @Test func integerLiteral() {
    let I1: TimeSpecification = 100
    let I2: TimeSpecification = -100
    #expect(I1 == TimeSpecification(seconds:100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 1")
    #expect(I2 == TimeSpecification(seconds:-100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 2")
  }

  @Test func floatLiteral() {
    let F1: TimeSpecification = 1.1
    #expect(F1 == TimeSpecification(seconds:1, nanoseconds:100_000_000), "ExpressibleByFloatLiteral Test 1")
  }

  @Test func sumAndDifference() {
    let L1 = TimeSpecification(seconds:100, nanoseconds:123_456_789)
    let R1 = TimeSpecification(seconds:100, nanoseconds:987_654_321)
    #expect(L1 + R1 == TimeSpecification(seconds:201, nanoseconds:111_111_110), "Sum Test 1")
    #expect(L1 - R1 == TimeSpecification(seconds:0, nanoseconds:-864_197_532), "Difference Test 1")
  }

  @Test func description() {
    let spec = TimeSpecification(seconds: 123, nanoseconds: 456_789)
    #expect(spec.description == "123.000456789")
  }

  @Test func date() {
    let spec = TimeSpecification(seconds: 100, nanoseconds: 123_456_789)
    #expect(
      Date(timeIntervalSinceReferenceDate: spec)
      == Date(timeIntervalSinceReferenceDate: 100.123456789)
    )
  }
}
#else
class TimeSpecificationTests: XCTestCase {
  func test_normalization() {
    let N1 = TimeSpecification(seconds:0, nanoseconds:1_234_567_890)
    let N2 = TimeSpecification(seconds:-1, nanoseconds:-1_234_567_890)
    
    XCTAssertTrue(N1.seconds == 1 && N1.nanoseconds == 234_567_890, "Normalization Test 1")
    XCTAssertTrue(N2.seconds == -3 && N2.nanoseconds == 765_432_110, "Normalization Test 2")
  }
  
  func test_codable() throws {
    let spec = TimeSpecification(seconds: 123, nanoseconds: 456_789)
    let encoded = try JSONEncoder().encode(spec)
    let encodedString = try XCTUnwrap(String(data: encoded, encoding: .utf8))
    // https://github.com/YOCKOW/SwiftTimeSpecification/runs/703218186?check_suite_focus=true#step:6:18
    XCTAssertTrue(encodedString == #"{"seconds":123,"nanoseconds":456789}"# ||
                  encodedString == #"{"nanoseconds":456789,"seconds":123}"#)
    
    let decoded = try JSONDecoder().decode(TimeSpecification.self, from: encoded)
    XCTAssertEqual(decoded, spec)
  }
  
  func test_comparison() {
    let C1 = TimeSpecification(seconds:100, nanoseconds:100)
    let C2 = TimeSpecification(seconds: 98, nanoseconds:2_000_000_100)
    let C3 = TimeSpecification(seconds:200, nanoseconds:100)
    let C4 = TimeSpecification(seconds:100, nanoseconds:200)
    XCTAssertEqual(C1, C2, "Comparison Test 1")
    XCTAssertTrue(C2 < C3, "Comparison Test 2")
    XCTAssertTrue(C2 < C4, "Comparison Test 3")
  }
  
  func test_integerLiteral() {
    let I1: TimeSpecification = 100
    let I2: TimeSpecification = -100
    XCTAssertEqual(I1, TimeSpecification(seconds:100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 1")
    XCTAssertEqual(I2, TimeSpecification(seconds:-100, nanoseconds:0), "ExpressibleByIntegerLiteral Test 2")
  }
  
  func test_floatLiteral() {
    let F1: TimeSpecification = 1.1
    XCTAssertEqual(F1, TimeSpecification(seconds:1, nanoseconds:100_000_000), "ExpressibleByFloatLiteral Test 1")
  }
  
  func test_sumAndDifference() {
    let L1 = TimeSpecification(seconds:100, nanoseconds:123_456_789)
    let R1 = TimeSpecification(seconds:100, nanoseconds:987_654_321)
    XCTAssertEqual(L1 + R1, TimeSpecification(seconds:201, nanoseconds:111_111_110), "Sum Test 1")
    XCTAssertEqual(L1 - R1, TimeSpecification(seconds:0, nanoseconds:-864_197_532), "Difference Test 1")
  }
  
  func test_description() {
    let spec = TimeSpecification(seconds: 123, nanoseconds: 456_789)
    XCTAssertEqual(spec.description, "123.000456789")
  }
  
  func test_date() {
    let spec = TimeSpecification(seconds: 100, nanoseconds: 123_456_789)
    XCTAssertEqual(Date(timeIntervalSinceReferenceDate: spec),
                   Date(timeIntervalSinceReferenceDate: 100.123456789))
  }
}
#endif
