##GCD in Swfit 3.0
This project is "forked" from [raywenderlich GCD tutorial] (https://www.raywenderlich.com/60749/grand-central-dispatch-in-depth-part-1). In Swift 3.0, lots of API in iOS SDK have been modified. Including how GCD APIs are called.

- `dispatch_get_global_queue` => `DispatchQueue.global(qos:)`
  before:
  ```Swfit
  dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
  ```
  Swift 3.0
  ```Swift
  DispatchQueue.global(qos: .userInteractive)
  ```
