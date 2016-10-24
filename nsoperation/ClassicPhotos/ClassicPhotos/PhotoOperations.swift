//
//  PhotoOperations.swift
//  ClassicPhotos
//
//  Created by Laks Gandikota on 8/24/16.
//  Copyright © 2016 raywenderlich. All rights reserved.
//

import UIKit

enum PhotoRecordState {
  case new, downloaded, filtered, failed
}

class PhotoRecord {
  
  let name: String
  let url: URL
  
  var state = PhotoRecordState.new
  var image = UIImage(named: "Placeholder")
  
  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }
  
}

// Class to track the status of the each operation
class PendingOperations {
  
  lazy var downloadInProgress = [IndexPath:Operation]()
  
  lazy var downloadQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Dowload Queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
  
  lazy var filtrationsInProgress = [IndexPath:Operation]()
  
  lazy var filtrationQueue: OperationQueue = {
    var queue = OperationQueue()
    queue.name = "Image Filtration Queue"
    queue.maxConcurrentOperationCount = 1
    return queue
  }()
}

//Operation for downloading
class ImageDownloader: Operation {
  
  let photoRecord: PhotoRecord
  
  init(photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }
  
  override func main() {
    
    if self.isCancelled {
      return
    }
    
    if let imageData = try? Data(contentsOf: self.photoRecord.url) {
      if self.isCancelled {
        return
      }
      
      if imageData.count > 0 {
        self.photoRecord.image = UIImage(data: imageData as Data)
        self.photoRecord.state = .downloaded
      } else {
        self.photoRecord.state = .failed
        self.photoRecord.image = UIImage(named: "Failed")
      }
    } else {
      return
    }
  }
}

//Operation for Filtering
class ImageFiltration: Operation {
  
  let photoRecord: PhotoRecord
  
  init(photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }
  
  override func main() {
    if self.isCancelled {
      return
    }
    
    if self.photoRecord.state != .downloaded {
      return
    }
    
    if let filteredImage = self.applySephiaFilter(self.photoRecord.image!) {
      self.photoRecord.image = filteredImage
      self.photoRecord.state = .filtered
    }
  }
  
  func applySephiaFilter(_ image: UIImage) -> UIImage? {
    let inputImage = CIImage(data: UIImagePNGRepresentation(image)!)
    
    if self.isCancelled {
      return nil
    }
    
    let context = CIContext()
    let filter = CIFilter(name: "CISepiaTone")
    filter?.setValue(inputImage, forKey: kCIInputImageKey)
    filter?.setValue(0.8, forKey: "inputIntensity")
    
    let outputImage = filter?.outputImage
    
    if self.isCancelled {
      return nil
    }
    
    let outImage = context.createCGImage(outputImage!, from: (outputImage?.extent)!)
    let returnImage = UIImage(cgImage: outImage!)
    return returnImage
    
  }
}
