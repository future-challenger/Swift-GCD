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

import AssetsLibrary
import UIKit

typealias PhotoDownloadCompletionBlock = (_ image: UIImage?, _ error: NSError?) -> Void
typealias PhotoDownloadProgressBlock = (_ completed: Int, _ total: Int) -> Void

enum PhotoStatus {
  case downloading
  case goodToGo
  case failed
}

protocol Photo {
  var status: PhotoStatus { get }
  var image: UIImage? { get }
  var thumbnail: UIImage? { get }
}

class AssetPhoto: Photo {
  var status: PhotoStatus {
    return .goodToGo
  }

  var image: UIImage? {
    let representation = asset.defaultRepresentation()
    return UIImage(cgImage: (representation?.fullScreenImage().takeUnretainedValue())!)
  }
  
  var thumbnail: UIImage? {
    return UIImage(cgImage: asset.thumbnail().takeUnretainedValue())
  }

  let asset: ALAsset

  init(asset: ALAsset) {
    self.asset = asset
  }
}

private let downloadSession = URLSession(configuration: URLSessionConfiguration.ephemeral)

class DownloadPhoto: Photo {
  var status: PhotoStatus = .downloading
  var image: UIImage?
  var thumbnail: UIImage?

  let url: URL

  init(url: URL, completion: PhotoDownloadCompletionBlock!) {
    self.url = url
    downloadImage(completion)
  }

  convenience init(url: URL) {
    self.init(url: url, completion: nil)
  }

  func downloadImage(_ completion: PhotoDownloadCompletionBlock?) {
    let task = downloadSession.dataTask(with: url, completionHandler: {
      data, response, error in
      self.image = UIImage(data: data!)
      if error == nil && self.image != nil {
        self.status = .goodToGo
      } else {
        self.status = .failed
      }

      self.thumbnail = self.image?.thumbnailImage(64,
        transparentBorder: 0,
        cornerRadius: 0,
        interpolationQuality: CGInterpolationQuality.default)

      if let completion = completion {
        completion(self.image, error as NSError?)
      }

      DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(rawValue: PhotoManagerContentUpdateNotification), object: nil)
      }
    })

    task.resume()
  }
}
