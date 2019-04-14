/***************************************************************************************************
 TimeSpecification.swift
  © 2016-2019 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
private let mach_task_self:() -> mach_port_t = { return mach_task_self_ }
private typealias CTimeSpec = mach_timespec_t
#else
import Glibc
private typealias CTimeSpec = timespec
#endif

/// The representation for the time in nanoseconds.
public struct TimeSpecification {
  public var seconds: Int64 = 0
  private var _nanoseconds: Int32 = 0
}

extension TimeSpecification {
  private mutating func _normalize() {
   //`nanoseconds` must be always zero or positive value and less than 1_000_000_000
    if self._nanoseconds >= 1_000_000_000 {
      self.seconds += Int64(self._nanoseconds / 1_000_000_000)
      self._nanoseconds = self._nanoseconds % 1_000_000_000
    } else if self._nanoseconds < 0 {
      // For example,
      //   (seconds:3, nanoseconds:-2_123_456_789)
      //   -> (seconds:0, nanoseconds:876_543_211)
      self.seconds += Int64(self._nanoseconds / 1_000_000_000) - 1
      self._nanoseconds = self._nanoseconds % 1_000_000_000 + 1_000_000_000
    }
  }
  
  public var nanoseconds: Int32 {
    get {
      return self._nanoseconds
    }
    set {
      self._nanoseconds = newValue
      self._normalize()
    }
  }
}

extension TimeSpecification {
  public init(seconds:Int64, nanoseconds:Int32) {
    self.seconds = seconds
    self.nanoseconds = nanoseconds // will be normalized
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
  }
  
  private init(_ cts:CTimeSpec) {
    self.init(seconds:Int64(cts.tv_sec), nanoseconds:Int32(cts.tv_nsec))
  }
  
  /// Initialze with an instance of `Clock`.
  public init(clock:Clock) {
    var c_timespec:CTimeSpec = CTimeSpec(tv_sec:0, tv_nsec:0)
    let clock_id:CInt

    #if os(Linux)
      clock_id = (clock == .calendar) ? CLOCK_REALTIME : CLOCK_MONOTONIC
      _ = clock_gettime(clock_id, &c_timespec)
    #elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
      var clock_name: clock_serv_t = 0
      clock_id = (clock == .calendar) ? CALENDAR_CLOCK : SYSTEM_CLOCK
      _ = host_get_clock_service(mach_host_self(), clock_id, &clock_name)
      _ = clock_get_time(clock_name, &c_timespec)
      _ = mach_port_deallocate(mach_task_self(), clock_name)
    #endif

    self.init(c_timespec)
  }
}
