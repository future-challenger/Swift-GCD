//
//  ExDispatchQueue.swift
//  GooglyPuff
//
//  Created by Li challenger on 31/10/2016.
//  Copyright © 2016 raywenderlich.com. All rights reserved.
//

import Foundation

extension DispatchQueue {
  private static var _onceTracker = [String]()
  
  public class func once(file: String = #file, function: String = #function, line: Int = #line, block:(Void)->Void) {
    let token = file + ":" + function + ":" + String(line)
    once(token: token, block: block)
  }
  
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
