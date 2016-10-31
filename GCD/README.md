##GCD in Swfit 3.0
This project is "forked" from [raywenderlich GCD tutorial] (https://www.raywenderlich.com/60749/grand-central-dispatch-in-depth-part-1). It's really a good tutorial where I learned what I wanted. But it's kinda out of date. In Swift 3.0, lots of API in iOS SDK have been modified. Including how GCD APIs are called. So I update the tutorial to swift 3.0

###Create a block
before:
```swift
      let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) { // 3
        // things to do in this block
      }
```
swift 3.0
```swift
      let block = DispatchWorkItem{
        let index = Int(i)
        let address = addresses[index]
        let url = URL(string: address)
        let photo = DownloadPhoto(url: url!) {
          image, error in
          if let error = error {
            storedError = error
          }
          downloadGroup.leave()
        }
        PhotoManager.sharedManager.addPhoto(photo)
      }
```

###Create a Queue

####Concurrent Queue
before:
```swift
let concurrentQueue = dispatch_queue_create("com.swift3.imageQueue", DISPATCH_QUEUE_CONCURRENT)
```

swift 3.0
```swift
let concurrentQueue = DispatchQueue(label: "com.swift3.imageQueue", attributes: .concurrent)
concurrentQueue.async {
  print("async task")
}  
```
####Serial Queue
before:
```swift
let concurrentQueue = dispatch_queue_create("com.swift3.imageQueue", DISPATCH_QUEUE_SERIAL)
```

swift 3.0
```swift
let concurrentQueue = DispatchQueue(label: "com.swift3.imageQueue")
concurrentQueue.sync {
  print("sync task")
}  
```

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
####Dispatch After
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

####Disaptch Once
This `dispatch_once` on longer exists in Swift 3.0.

According to Apple's migration guide:
```
The free function dispatch_once is no longer available in Swift. In Swift, you can use lazily initialized globals or static properties and get the same thread-safety and called-once guarantees as dispatch_once provided.
```
You can use lazy initialized global or static properties instead of dispatch once. eg:
```swift
// global constant: SomeClass initializer gets called lazily, only on first use
let foo = SomeClass()

// global var, same thing happens here
// even though the "initializer" is an immediately invoked closure
var bar: SomeClass = {
    let b = SomeClass()
    b.someProperty = "whatever"
    b.doSomeStuff()
    return b
}()

// ditto for static properties in classes/structures/enums
class MyClass {
    static let singleton = MyClass()
    init() {
        print("foo")
    }
}
```

#### Dispatch Once Is Still Needed
Global var or static property can not meet our needs when we just need some code run once in app. And this code has a reference to `self`. Static property makes this not possible. Let's checkout some other ways to use "*dispatch onde*" in Swift 3.0.
It fits *Singleton* very well, but not the run-once thing.

The first one:
```swift
public extension DispatchQueue {
    private static var _onceTracker = [String]()

    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.

     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:@noescape(Void)->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
```

How to use the `once` function:
```swift
DispatchQueue.once(token: "com.vectorform.test") {
    print( "Do This Once!" )
}
```
or:
```swift
private let _onceToken = NSUUID().uuidString

DispatchQueue.once(token: _onceToken) {
    print( "Do This Once!" )
}
```
**NOTE**: You have to use your own **tracker** to prevent your code run more than once.

Let's make some improvement:
```swift
public extension DispatchQueue {
    private static var _onceTracker = [String]()

    public class func once(file: String = #file, function: String = #function, line: Int = #line, block:(Void)->Void) {
        let token = file + ":" + function + ":" + String(line)
        once(token: token, block: block)
    }

    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.

     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:(Void)->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }


        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
```
How to use it:
```swift
DispatchQueue.once {
    setupUI()
}
```
or:
```swift
DispatchQueue.once(token: "com.me.project") {
    setupUI()
}
```
You can use a string *tracker*, you also can use the default *tracker*.

But there's another way. You can define another name for *dispatch_once* in an ObjC file, and use it in swift 3.0 with the "Bridege Header" imported.
```objective-c
// in header
typedef dispatch_once_t mxcl_dispatch_once_t;
void mxcl_dispatch_once(mxcl_dispatch_once_t *predicate, dispatch_block_t block);

// in source file
void mxcl_dispatch_once(mxcl_dispatch_once_t *predicate, dispatch_block_t block) {
    dispatch_once(predicate, block);
}
```
You can use `mxcl_dispatch_once` in swift.

###Create Source &
before:
```swift
    let queue = dispatch_get_main_queue()
    self.signalSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL,
                                               UInt(SIGSTOP), 0, queue) // 3
    if let source = self.signalSource { // 4
      dispatch_source_set_event_handler(source) { // 5
        NSLog("Hi, I am: \(self.description)")
      }
      dispatch_resume(source) // 6
    }
```

Swift 3.0:
```swift
    let queue = DispatchQueue.main
    self.signalSource = DispatchSource.makeSignalSource(signal: 0, queue: queue) // 3
    if let source = self.signalSource { // 4
        source.setEventHandler(handler: { // 5
        print("Hi, I am: \(self.description)")
        })
        source.resume() // 6
    }
```

reference: <br />
http://stackoverflow.com/questions/37801407/whither-dispatch-once-in-swift-3
http://stackoverflow.com/questions/37801436/how-do-i-write-dispatch-after-gcd-in-swift-3
http://stackoverflow.com/questions/37886994/dispatch-once-in-swift-3
