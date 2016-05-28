# What is SwiftTimeSpecification?
SwiftTimeSpecification is an implementation of `struct timespec` in Swift Programming Language.  
Its prototype is [YOCKOW's Gist](https://gist.github.com/YOCKOW/12d9607cb30f40b79fb2).  

# How to use
Build and install:  
`./build.rb --install-prefix=/path/to/your/system`  
Then, you can use it:    
`swiftc ./your/project/main.swift -I/path/to/your/system/include -L/path/to/your/system/lib`  

# Sample Code
``
import TimeSpecification
let start = Clock.System.timeSpecification()
// your code
let end = Clock.System.timeSpecification()

if start != nil && end != nil {
  let duration = end! - start!
  print("\(duration)")
}
``
