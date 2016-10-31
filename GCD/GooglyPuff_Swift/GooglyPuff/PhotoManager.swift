//
//  Utils.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 07.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//
//  Updated by Uncle Charlie
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
    var storedError: NSError?
    for address in [OverlyAttachedGirlfriendURLString,
                    SuccessKidURLString,
                    LotsOfFacesURLString] {
      let url = URL(string: address)
      let photo = DownloadPhoto(url: url!) {
        image, error in
        if error != nil {
          storedError = error
        }
      }
      PhotoManager.sharedManager.addPhoto(photo)
    }

    if let completion = completion {
      completion(storedError)
    }
  }

  fileprivate func postContentAddedNotification() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: PhotoManagerAddedContentNotification), object: nil)
  }
}
