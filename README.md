# What is SwiftTimeSpecification?
SwiftTimeSpecification is an implementation of `struct timespec` (`struct mach_timespec` on OS X) in Swift Programming Language.  
Its prototype is [YOCKOW's Gist](https://gist.github.com/YOCKOW/12d9607cb30f40b79fb2).  

|Branch     |Build Status                                                                                                                                      |
|:---------:|:------------------------------------------------------------------------------------------------------------------------------------------------:|
|master     |[![Build Status](https://travis-ci.org/YOCKOW/SwiftTimeSpecification.svg?branch=master)     ](https://travis-ci.org/YOCKOW/SwiftTimeSpecification)|
|development|[![Build Status](https://travis-ci.org/YOCKOW/SwiftTimeSpecification.svg?branch=development)](https://travis-ci.org/YOCKOW/SwiftTimeSpecification)|

## Class, Structure, Enumeration
```
public struct TimeSpecification: Comparable,
                                 ExpressibleByIntegerLiteral,
                                 ExpressibleByFloatLiteral {
  public var seconds:Int64 = 0
  public var nanoseconds:Int32 = 0
  /* ... */
}
public enum Clock {
  case Calendar
  case System
  
  public func timeSpecification() -> TimeSpecification? {
    /* ... */
  }
}
```

# How to use
Build and install:  
`./build-install.rb --install-prefix=/path/to/your/system --install`  
Then, you can use it in your project:  
`swiftc ./your/project/main.swift -I/path/to/your/system/include -L/path/to/your/system/lib`  

# Sample Code
```
import TimeSpecification
let start = Clock.System.timeSpecification()
// your code
let end = Clock.System.timeSpecification()

if start != nil && end != nil {
  let duration = end! - start!
  // For example, duration == TimeSpecification(seconds:0, nanoseconds:100)
  print("\(duration)") 
}
```
