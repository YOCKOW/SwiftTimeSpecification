/***************************************************************************************************
 TimeSpecification.swift
  © 2016-2020,2024 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

#if canImport(Darwin)
@preconcurrency import Darwin
private let mach_task_self: @Sendable () -> mach_port_t = { mach_task_self_ }
private typealias _CTimeSpec = mach_timespec_t
#else
import Glibc
private typealias _CTimeSpec = timespec
#endif

import Foundation

/// The representation for the time in nanoseconds.
public struct TimeSpecification: Sendable {
  public var seconds: Int64 = 0
  
  private var _nanoseconds: Int32 = 0
  public var nanoseconds: Int32 {
    get {
      return self._nanoseconds
    }
    set {
      self._nanoseconds = newValue
      self._normalize()
    }
  }
  
  private mutating func _normalize() {
   //`nanoseconds` must be always zero or positive value and less than 1_000_000_000
    if self._nanoseconds >= 1_000_000_000 {
      let quotRem: div_t = div(self._nanoseconds, 1_000_000_000)
      self.seconds += Int64(quotRem.quot)
      self._nanoseconds = quotRem.rem
    } else if self._nanoseconds < 0 {
      // For example,
      //   (seconds:3, nanoseconds:-2_123_456_789)
      //   -> (seconds:0, nanoseconds:876_543_211)
      let quotRem: div_t = div(self._nanoseconds, 1_000_000_000)
      self.seconds += Int64(quotRem.quot) - 1
      self._nanoseconds = quotRem.rem + 1_000_000_000
    }
  }
  
  private init(_noNormalizationRequired time: (seconds: Int64, nanoseconds: Int32)) {
    self.seconds = time.seconds
    self._nanoseconds = time.nanoseconds
  }
  
  public init(seconds: Int64, nanoseconds: Int32) {
    self.seconds = seconds
    self.nanoseconds = nanoseconds // will be normalized
  }
}

extension TimeSpecification: Codable {
  public enum CodingKeys: String, CodingKey {
    case seconds, nanoseconds
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.seconds, forKey: .seconds)
    try container.encode(self.nanoseconds, forKey: .nanoseconds)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let seconds = try container.decode(Int64.self, forKey: .seconds)
    let nanoseconds = try container.decode(Int32.self, forKey: .nanoseconds)
    self.init(seconds: seconds, nanoseconds: nanoseconds)
  }
}

extension TimeSpecification: Equatable {
  public static func ==(lhs:TimeSpecification, rhs:TimeSpecification) -> Bool {
    return lhs.seconds == rhs.seconds && lhs.nanoseconds == rhs.nanoseconds
  }
}

extension TimeSpecification: Comparable {
  public static func < (lhs: TimeSpecification, rhs: TimeSpecification) -> Bool {
    if lhs.seconds < rhs.seconds { return true }
    if lhs.seconds > rhs.seconds { return false }
    // Then, in the case of (lhs.seconds == rhs.seconds) ...
    return lhs.nanoseconds < rhs.nanoseconds
  }
}

extension TimeSpecification: Hashable {
  public func hash(into hasher:inout Hasher) {
    hasher.combine(self.seconds)
    hasher.combine(self.nanoseconds)
  }
}

extension TimeSpecification: ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = Int64
  public init(integerLiteral value: Int64) {
    self.init(seconds: value, nanoseconds: 0)
  }
}

extension TimeSpecification: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = Double
  public init(floatLiteral value:Double) {
    let double_seconds = floor(value)
    self.init(seconds: Int64(double_seconds), nanoseconds: Int32((value - double_seconds) * 1.0E+9))
  }
  
  /// Creates an instance initialized to the specified floating-point value.
  public init<F>(_ value: F) where F: BinaryFloatingPoint {
    self.init(floatLiteral: FloatLiteralType(value))
  }
}

extension TimeSpecification {
  /// The value of seconds
  public var integerValue: Int { return Int(self.seconds) }
  
  /// Double representation of the time.
  @inlinable
  public var doubleValue: Double { return Double(self.nanoseconds) * 1.0E-9 + Double(self.seconds) }
  
  #if arch(i386) || arch(x86_64)
  /// Float80 representation of the time.
  @inlinable
  public var float80Value: Float80 {
    return Float80(self.nanoseconds) * 1.0E-9 + Float80(self.seconds)
  }
  #endif
}

extension TimeSpecification: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    return String(format:"\(self.seconds).%09d", self.nanoseconds)
  }
  
  public var debugDescription: String {
    return self.description + " seconds."
  }
}

// sum and difference
extension TimeSpecification {
  public static func +(lhs:TimeSpecification, rhs:TimeSpecification) -> TimeSpecification {
    var result = lhs
    result.seconds += rhs.seconds
    result.nanoseconds += rhs.nanoseconds // always normalized
    return result
  }
  
  public static func -(lhs:TimeSpecification, rhs:TimeSpecification) -> TimeSpecification {
    var result = lhs
    result.seconds -= rhs.seconds
    result.nanoseconds -= rhs.nanoseconds // always normalized
    return result
  }
  
  public static func +=(lhs:inout TimeSpecification, rhs:TimeSpecification) {
    lhs = lhs + rhs // always normalized
  }
  
  public static func -=(lhs:inout TimeSpecification, rhs:TimeSpecification) {
    lhs = lhs - rhs // always normalized
  }
}

extension TimeSpecification {
  public enum Clock {
    /// Calendar Clock
    ///
    /// Note: This means `CLOCK_REALTIME` on Linux, `CALENDAR_CLOCK` on macOS.
    case calendar
    
    /// System Clock
    ///
    /// Note: This means `CLOCK_MONOTONIC` on Linux, `SYSTEM_CLOCK` on macOS.
    case system
    
    fileprivate var _clockID: CInt {
      switch self {
      case .calendar:
        #if canImport(Darwin)
        return CALENDAR_CLOCK
        #else
        return CLOCK_REALTIME
        #endif
      case .system:
        #if canImport(Darwin)
        return SYSTEM_CLOCK
        #else
        return CLOCK_MONOTONIC
        #endif
      }
    }
  }
  
  private init(_ cts: _CTimeSpec) {
    self.init(_noNormalizationRequired: (seconds: Int64(cts.tv_sec),
                                         nanoseconds: Int32(cts.tv_nsec)))
  }
  
  /// Initialze with an instance of `Clock`.
  public init(clock: Clock) {
    var c_timespec: _CTimeSpec = _CTimeSpec(tv_sec:0, tv_nsec:0)

    #if os(Linux)
      _ = clock_gettime(clock._clockID, &c_timespec)
    #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      var clock_name: clock_serv_t = 0
      _ = host_get_clock_service(mach_host_self(), clock._clockID, &clock_name)
      _ = clock_get_time(clock_name, &c_timespec)
      _ = mach_port_deallocate(mach_task_self(), clock_name)
    #endif

    self.init(c_timespec)
  }
}

/// Type used to represent a specific point in time relative
/// to the absolute reference date of 1 Jan 2001 00:00:00 GMT.
public typealias NanosecondAbsoluteTime = TimeSpecification

/// Type used to represent elapsed time in naoseconds.
public typealias NanosecondTimeInterval = TimeSpecification

extension TimeSpecification {
  /// The number of nanoseconds from 1 January 1970 to the reference date, 1 January 2001.
  public static let timeIntervalBetween1970AndReferenceDate = NanosecondTimeInterval(Date.timeIntervalBetween1970AndReferenceDate)
  
  /// The interval between 00:00:00 UTC on 1 January 2001 and the current date and time.
  public static var timeIntervalSinceReferenceDate: NanosecondAbsoluteTime {
    return TimeSpecification(clock: .calendar) - TimeSpecification.timeIntervalBetween1970AndReferenceDate
  }
}

extension TimeSpecification {
  /// Measure a processing time of the closure.
  ///
  /// - parameters:
  ///   * repeatCount: Indicates the number of times to execute the closure. It must be greater than zero.
  ///   * body: The target closure.
  public static func measure(repeatCount: Int = 1, _ body: () throws -> Void) rethrows -> TimeSpecification {
    precondition(repeatCount > 0, "\(#function): `repeatCount` must be greater than zero.")
    let start = TimeSpecification(clock: .system)
    for _ in 0..<repeatCount { try body() }
    let end = TimeSpecification(clock: .system)
    return end - start
  }
}
