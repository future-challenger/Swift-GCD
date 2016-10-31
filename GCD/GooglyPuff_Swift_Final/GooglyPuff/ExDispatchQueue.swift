//
//  Utils.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 07.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//
//  Updated by Uncle Charlie 2016 10 31
//  https://github.com/future-challenger/Swift3.0/tree/master/GCD
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
