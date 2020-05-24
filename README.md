# What is SwiftTimeSpecification?
SwiftTimeSpecification is an implementation of `struct timespec` (`struct mach_timespec` on OS X) in Swift.  
Its prototype is [YOCKOW's Gist](https://gist.github.com/YOCKOW/12d9607cb30f40b79fb2).  


## Sample Code

### Measure

```Swift
import TimeSpecification

func time(_ body:() -> Void) {
  let start = TimeSpecification(clock: .system)
  body()
  let end = TimeSpecification(clock: .system)
  let duration = end - start
  print("\(duration)")
}
```

### With `Date`

```Swift
import TimeSpecification

let now = TimeSpecification(clock: .calendar)
let dateNow = Date(timeIntervalSince1970: now)
```


# Requirements

- Swift 5 (including compatibility mode for 4, 4.2)
- macOS or Linux


# License

MIT License.  
See "LICENSE.txt" for more information.
