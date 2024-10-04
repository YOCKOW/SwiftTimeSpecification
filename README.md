# What is SwiftTimeSpecification?
SwiftTimeSpecification is an implementation of `struct timespec` (`struct mach_timespec` on OS X) in Swift.  
Its prototype is [YOCKOW's Gist](https://gist.github.com/YOCKOW/12d9607cb30f40b79fb2).  


## Sample Code

### Measure

```Swift
import TimeSpecification

let duration = TimeSpecification.measure(repeatCount: 100) { doIt() }
print("It took \(duration) seconds.") // -> Processing time to execute `doIt` 100 times. 

```

### With `Date`

```Swift
import TimeSpecification

let now = TimeSpecification(clock: .calendar)
let dateNow = Date(timeIntervalSince1970: now) // -> Almost same with Date(timeIntervalSince1970: Double(time(nil)))
```


# Requirements

- Swift 5, 6 (including language mode for 4, 4.2)
- macOS or Linux


# License

MIT License.  
See "LICENSE.txt" for more information.
