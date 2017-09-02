/***************************************************************************************************
 TimeSpecification.swift
  © 2016-2017 YOCKOW.
    Licensed under MIT License.
    See "LICENSE.txt" for more information.
 **************************************************************************************************/

#if os(Linux)
  import Glibc
  private typealias CTimeSpec = timespec
#elseif os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
  import Darwin
  private let mach_task_self:() -> mach_port_t = { return mach_task_self_ }
  private typealias CTimeSpec = mach_timespec_t
#else
  // UNKNOWN OS
#endif

public struct TimeSpecification: Comparable,
                                 ExpressibleByIntegerLiteral,
                                 ExpressibleByFloatLiteral {
  public var seconds:Int64 = 0
  public var nanoseconds:Int32 = 0 {
    didSet { self.normalize() }
  }
  
  public init(seconds:Int64, nanoseconds:Int32) {
    self.seconds = seconds
    self.nanoseconds = nanoseconds
    self.normalize()
  }
  
  public mutating func normalize() {
    // `nanoseconds` must be always zero or positive value and less than 1_000_000_000
    if self.nanoseconds >= 1_000_000_000 {
      self.seconds += Int64(self.nanoseconds / 1_000_000_000)
      self.nanoseconds = self.nanoseconds % 1_000_000_000
    } else if self.nanoseconds < 0 {
      // For example,
      //   (seconds:3, nanoseconds:-2_123_456_789)
      //   -> (seconds:0, nanoseconds:876_543_211)
      self.seconds += Int64(self.nanoseconds / 1_000_000_000) - 1
      self.nanoseconds = self.nanoseconds % 1_000_000_000 + 1_000_000_000
    }
  }
}

/* Comparable */
public func ==(lhs:TimeSpecification, rhs:TimeSpecification) -> Bool {
  return (lhs.seconds == rhs.seconds && lhs.nanoseconds == rhs.nanoseconds) ? true : false
}
public func <(lhs:TimeSpecification, rhs:TimeSpecification) -> Bool {
  if lhs.seconds < rhs.seconds { return true }
  if lhs.seconds > rhs.seconds { return false }
  // then, in the case of (lhs.seconds == rhs.seconds)
  if (lhs.nanoseconds < rhs.nanoseconds) { return true }
  return false
}

/* ExpressibleByIntegerLiteral */
extension TimeSpecification {
  public typealias IntegerLiteralType = Int64
  public init(integerLiteral value:Int64) {
    self.seconds = value
    self.nanoseconds = 0
  }
}

/* ExpressibleByFloatLiteral */
extension TimeSpecification {
  public typealias FloatLiteralType = Double
  public init(floatLiteral value:Double) {
    self.seconds = Int64(floor(value))
    self.nanoseconds = Int32((value - Double(self.seconds)) * 1.0E+9)
  }
}

/* Sum And Difference */
public func + (lhs:TimeSpecification, rhs:TimeSpecification) -> TimeSpecification {
  var result = lhs
  result.seconds += rhs.seconds
  result.nanoseconds += rhs.nanoseconds // always normalized
  return result
}
public func - (lhs:TimeSpecification, rhs:TimeSpecification) -> TimeSpecification {
  var result = lhs
  result.seconds -= rhs.seconds
  result.nanoseconds -= rhs.nanoseconds // always normalized
  return result
}
public func += (lhs:inout TimeSpecification, rhs:TimeSpecification) {
  lhs = lhs + rhs // always normalized
}
public func -= (lhs:inout TimeSpecification, rhs:TimeSpecification) {
  lhs = lhs - rhs // always normalized
}

/* Clock */
extension TimeSpecification {
  fileprivate init(_ cts:CTimeSpec) {
    self.seconds = Int64(cts.tv_sec)
    self.nanoseconds = Int32(cts.tv_nsec)
  }
}
public enum Clock {
  case Calendar
  case System
  
  public func timeSpecification() -> TimeSpecification? {
    var c_timespec:CTimeSpec = CTimeSpec(tv_sec:0, tv_nsec:0)
    
    let clock_id:CInt
    var retval:CInt = -1
    
    #if os(Linux)
      clock_id = (self == .Calendar) ? CLOCK_REALTIME : CLOCK_MONOTONIC
      retval = clock_gettime(clock_id, &c_timespec)
    #elseif os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
      var clock_name: clock_serv_t = 0
      clock_id = (self == .Calendar) ? CALENDAR_CLOCK : SYSTEM_CLOCK
      retval = host_get_clock_service(mach_host_self(), clock_id, &clock_name)
      if retval != 0 { return nil }
      retval = clock_get_time(clock_name, &c_timespec)
      _ = mach_port_deallocate(mach_task_self(), clock_name)
    #endif
    
    return (retval == 0) ? TimeSpecification(c_timespec) : nil
  }
}
