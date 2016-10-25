##GCD in Swfit 3.0
This project is "forked" from [raywenderlich GCD tutorial] (https://www.raywenderlich.com/60749/grand-central-dispatch-in-depth-part-1). It's really a good tutorial where I learned what I wanted. But it's kinda out of date. In Swift 3.0, lots of API in iOS SDK have been modified. Including how GCD APIs are called. So I update the tutorial to swift 3.0

###Main Queue
`dispatch_get_main_queue` => `DispatchQueue.main`

###Global Queue
`dispatch_get_global_queue` => `DispatchQueue.global(qos:)`
before:
```Swfit
dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
```
Swift 3.0
```Swift
DispatchQueue.global(qos: .userInteractive)
```

Here's a easy one. Before we always do things like this:
```Swift
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    // do something background
    dispatch_async(dispatch_get_main_queue(), ^{
        // update UI in main thread(or UI thread)
    });
});
```
In swift 3.0, we do it this way.
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // background things
    DispatchQueue.main.async {
        print("main thread dispatch")
    }
}
```

###Dispatch After & Once
before you do dispatch after like this:
```swift
var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
dispatch_after(dispatchTime, dispatch_get_main_queue(), {
    // your function here
})
```
In swift 3.0
```swift
let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
    // your function here
})
```
or even more simply:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    // your function here
}
```
