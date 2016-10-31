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

/// Notification when new photo instances are added
let PhotoManagerAddedContentNotification = "com.raywenderlich.GooglyPuff.PhotoManagerAddedContent"
/// Notification when content updates (i.e. Download finishes)
let PhotoManagerContentUpdateNotification = "com.raywenderlich.GooglyPuff.PhotoManagerContentUpdate"

typealias PhotoProcessingProgressClosure = (_ completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (_ error: NSError?) -> Void

private let _sharedManager = PhotoManager()

class PhotoManager {
  class var sharedManager: PhotoManager {
    return _sharedManager
  }

  fileprivate var _photos: [Photo] = []
  var photos: [Photo] {
    var photosCopy: [Photo]!
    concurrentPhotoQueue.sync { // 1
      photosCopy = self._photos // 2
    }
    return photosCopy
  }

  fileprivate let concurrentPhotoQueue = DispatchQueue(
    label: "com.raywenderlich.GooglyPuff.photoQueue", attributes: DispatchQueue.Attributes.concurrent)

  func addPhoto(_ photo: Photo) {
    concurrentPhotoQueue.async(flags: .barrier, execute: { // 1
      self._photos.append(photo) // 2
      GlobalMainQueue.async { // 3
        self.postContentAddedNotification()
      }
    }) 
  }

  func downloadPhotosWithCompletion(_ completion: BatchPhotoDownloadingCompletionClosure?) {
    var storedError: NSError!
    let downloadGroup = DispatchGroup()
    var addresses = [OverlyAttachedGirlfriendURLString,
                     SuccessKidURLString,
                     LotsOfFacesURLString]
    addresses += addresses + addresses // 1
    var blocks: [DispatchWorkItem] = [] // 2

    for i in 0 ..< addresses.count {
      downloadGroup.enter()
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
      
      blocks.append(block)
      GlobalMainQueue.async(execute: block) // 4
    }

    for block in blocks[3 ..< blocks.count] { // 5
      let cancel = arc4random_uniform(2) // 6
      if cancel == 1 {
        block.cancel()  // 7
        downloadGroup.leave() // 8
      }
    }

    downloadGroup.notify(queue: GlobalMainQueue) {
      if let completion = completion {
        completion(storedError)
      }
    }
  }

  fileprivate func postContentAddedNotification() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: PhotoManagerAddedContentNotification), object: nil)
  }
}
