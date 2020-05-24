/* *************************************************************************************************
 Date+TimeSpecification.swift
   © 2020 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */
 
import Foundation

extension TimeSpecification {
  @inlinable
  public var timeIntervalValue: TimeInterval {
    return TimeInterval(self.doubleValue)
  }
}

extension Date {
  /// Creates a date value initialized relative to the current date and time
  /// by a given number of nanoseconds.
  @inlinable
  public init(timeIntervalSinceNow: TimeSpecification) {
    self.init(timeIntervalSinceNow: timeIntervalSinceNow.timeIntervalValue)
  }
  
  /// Creates a date value initialized relative to another given date
  /// by a given number of nanoseconds.
  @inlinable
  public init(timeInterval: TimeSpecification, since date: Date) {
    self.init(timeInterval: timeInterval.timeIntervalValue, since: date)
  }
  
  /// Creates a date value initialized relative to 00:00:00 UTC on 1 January 2001
  /// by a given number of nanoseconds.
  @inlinable
  public init(timeIntervalSinceReferenceDate: TimeSpecification) {
    self.init(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.timeIntervalValue)
  }
  
  /// Creates a date value initialized relative to 00:00:00 UTC on 1 January 1970
  /// by a given number of nanoseconds.
  @inlinable
  public init(timeIntervalSince1970: TimeSpecification) {
    self.init(timeIntervalSince1970: timeIntervalSince1970.timeIntervalValue)
  }
}
