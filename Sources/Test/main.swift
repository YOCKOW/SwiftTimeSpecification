/***************************************************************************************************
 test.swift
  © 2016 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

// FIXME: These are irresponsible tests below.

#if os(Linux)
  import Glibc
#elseif os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
  import Darwin
#else
  // UNKNOWN OS
#endif

import TimeSpecification

let test = TAP()

// Normalization Tests
let N1 = TimeSpecification(seconds:0, nanoseconds:1_234_567_890)
let N2 = TimeSpecification(seconds:-1, nanoseconds:-1_234_567_890)
test.ok(N1.seconds == 1 && N1.nanoseconds == 234_567_890, "Normalization Test 1")
test.ok(N2.seconds == -3 && N2.nanoseconds == 765_432_110, "Normalization Test 2")

// Comparison Tests
let C1 = TimeSpecification(seconds:100, nanoseconds:100)
let C2 = TimeSpecification(seconds: 98, nanoseconds:2_000_000_100)
let C3 = TimeSpecification(seconds:200, nanoseconds:100)
let C4 = TimeSpecification(seconds:100, nanoseconds:200)
test.eq(C1, C2, "Comparison Test 1")
test.ok(C2 < C3, "Comparison Test 2")
test.ok(C2 < C4, "Comparison Test 3")

// IntegerLiteralConvertible Tests
let I1 = TimeSpecification(integerLiteral:100)
let I2 = TimeSpecification(integerLiteral:-100)
test.eq(I1, TimeSpecification(seconds:100, nanoseconds:0), "Integer Literal Convertible Test 1")
test.eq(I2, TimeSpecification(seconds:-100, nanoseconds:0), "Integer Literal Convertible Test 2")

// FloatLiteralConvertible Tests
let F1 = TimeSpecification(floatLiteral:-1.1)
//// How to test...

// Sum and Difference Tests
let L1 = TimeSpecification(seconds:100, nanoseconds:123_456_789)
let R1 = TimeSpecification(seconds:100, nanoseconds:987_654_321)
test.eq(L1 + R1, TimeSpecification(seconds:201, nanoseconds:111_111_110), "Sum Test 1")
test.eq(L1 - R1, TimeSpecification(seconds:0, nanoseconds:-864_197_532), "Difference Test 1")

test.done(dontExit:true)

// Others
print("\nOTHERS")
print("C time(): \(time(nil))")
print("Calendar Clock: \(Clock.Calendar.timeSpecification()!)")
print("System Clock: \(Clock.System.timeSpecification()!)")
