// https://github.com/dankogai/swift-tap/blob/master/tap/tap.swift

//
//  tap.swift
//  tap
//
//  Created by Dan Kogai on 1/21/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//
/*
  The MIT License (MIT)

  Copyright (c) 2016 Dan Kogai

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
 */

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

open class TAP {
  var tests = 0, runs = [Bool]()
  public init() {}
  public init(tests:Int) {
    self.plan(tests)
  }
  /// sets the number of tests to run. call it before the first test
  open func plan(_ tests:Int) {
    self.tests = tests
    print("1..\(tests)")
  }
  /// ok if `predicate` is true
  @discardableResult
  open func ok(_ predicate:@autoclosure ()->Bool, _ message:String = "")->Bool {
    let ok = predicate()
    runs.append(ok)
    let ornot = ok ? "" : "not "
    print("\(ornot)ok \(runs.count) - \(message)")
    return ok
  }
  /// ok if `actual` == `expected`
  @discardableResult
  open func eq<T:Equatable>(_ actual:T, _ expected:T, _ message:String = "")->Bool {
    if ok(actual == expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: \(expected)")
    return false
  }
  /// ok if `actual` == `expected`
  @discardableResult
  open func eq<T:Equatable>(_ actual:T?, _ expected:T?, _ message:String = "")->Bool {
    if ok(actual == expected, message) { return true }
    print("#       got: \(actual as T?)")
    print("#  expected: \(expected as T?)")
    return false
  }
  /// ok if arrays are `actual` == `expected`
  @discardableResult
  open func eq<T:Equatable>(_ actual:[T], _ expected:[T], _ message:String = "")->Bool {
    if ok(actual == expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: \(expected)")
    return false
  }
  /// ok if dictionaries are `actual` == `expected`
  @discardableResult
  open func eq<K:Hashable,V:Equatable>(_ actual:[K:V], _ expected:[K:V], _ message:String = "")->Bool {
    if ok(actual == expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: \(expected)")
    return false
  }
  @discardableResult
  /// ok if `actual` != `expected`
  open func ne<T:Equatable>(_ actual:T, _ expected:T, _ message:String = "")->Bool {
    if ok(actual != expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: anthing but \(expected)")
    return false
  }
  /// ok if `actual` != `expected`
  @discardableResult
  open func ne<T:Equatable>(_ actual:T?, _ expected:T?, _ message:String = "")->Bool {
    if ok(actual != expected, message) { return true }
    print("#       got: \(actual as T?)")
    print("#  expected: anthing but \(expected as T?)")
    return false
  }
  /// ok if arrays are `actual` == `expected`
  @discardableResult
  open func ne<T:Equatable>(_ actual:[T], _ expected:[T], _ message:String = "")->Bool {
    if ok(actual != expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: anthing but \(expected)")
    return false
  }
  /// ok if dictionaries are `actual` == `expected`
  @discardableResult
  open func ne<K:Hashable,V:Equatable>(_ actual:[K:V], _ expected:[K:V], _ message:String = "")->Bool {
    if ok(actual != expected, message) { return true }
    print("#       got: \(actual)")
    print("#  expected: anthing but \(expected)")
    return false
  }
  /// checks the test results, print stuff if neccesary,
  /// and `exit()` with code == number of failures
  @discardableResult
  open func done(dontExit nx:Bool = false)->[Bool] {
    if runs.count == 0 && nx != true {
      print("# no test run!")
      exit(-1)
    }
    if tests == 0 {
      print("1..\(runs.count)")
    }
    else if runs.count != tests {
      print("not ok \(runs.count + 1) - planned to run \(tests) but actually ran \(runs.count)")
      runs.append(false)
      if nx != true { exit(-1) }
    }
    if nx != true {
      let code = min(254, runs.filter{ $0 == false }.count)
      exit(Int32(code))
    }
    return runs
  }
  deinit {
    done(dontExit:true)
  }
}
