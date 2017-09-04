# What is SwiftTimeSpecification?
SwiftTimeSpecification is an implementation of `struct timespec` (`struct mach_timespec` on OS X) in Swift Programming Language.  
Its prototype is [YOCKOW's Gist](https://gist.github.com/YOCKOW/12d9607cb30f40b79fb2).  

[![Build Status](https://travis-ci.org/YOCKOW/SwiftTimeSpecification.svg?branch=master)](https://travis-ci.org/YOCKOW/SwiftTimeSpecification)


## Class, Structure, Enumeration
```
public struct TimeSpecification {
  public var seconds:Int64 = 0
  public var nanoseconds:Int32 = 0
  /* ... */
}
public enum Clock {
  case Calendar
  case System
  
  public var timeSpecification: TimeSpecification? {
    /* ... */
  }
}
```

# How to use
Build and install:  
`./build-install.rb --install-prefix=/path/to/your/system --install`  
Then, you can use it in your project:  
`swiftc ./your/project/main.swift -I/path/to/your/system/include -L/path/to/your/system/lib -lSwiftTimeSpecification`  

# Sample Code
```
import TimeSpecification

func time(_ body:() -> Void) {
  guard let start = Clock.System.timeSpecification else { return }
  body()
  guard let end = Clock.System.timeSpecification else { return }
  let duration = end - start
  print("\(duration)")
}
```
