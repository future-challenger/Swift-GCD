//
//  Utils.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 07.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import Foundation

/// Photo Credit: Devin Begley, http://www.devinbegley.com/
let OverlyAttachedGirlfriendURLString = "http://i.imgur.com/UvqEgCv.png"
let SuccessKidURLString = "http://i.imgur.com/dZ5wRtb.png"
let LotsOfFacesURLString = "http://i.imgur.com/tPzTg7A.jpg"

var GlobalMainQueue: DispatchQueue {
  return DispatchQueue.main
}

var GlobalUserInteractiveQueue: DispatchQueue {
  return DispatchQueue.global(qos: .userInteractive)
}

var GlobalUserInitiatedQueue: DispatchQueue {
  return DispatchQueue.global(qos: .userInitiated)
}

var GlobalUtilityQueue: DispatchQueue {
  return DispatchQueue.global(qos: .utility)
}

var GlobalBackgroundQueue: DispatchQueue {
  return DispatchQueue.global(qos: .background)
}

class Utils: NSObject {
  @objc class var defaultBackgroundColor: UIColor {
    return UIColor(red: 236.0/255.0, green: 254.0/255.0, blue: 255.0/255.0, alpha: 1.0)
  }

  @objc class var userInterfaceIdiomIsPad: Bool {
    return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
  }
}

