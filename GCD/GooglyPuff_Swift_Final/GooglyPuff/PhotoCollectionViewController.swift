//
//  PhotoCollectionViewController.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 06.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import UIKit

private let CellImageViewTag = 3
private let BackgroundImageOpacity: CGFloat = 0.1

class PhotoCollectionViewController: UICollectionViewController {
  var library: ALAssetsLibrary!
  fileprivate var popController: UIPopoverController!

  fileprivate var contentUpdateObserver: NSObjectProtocol!
  fileprivate var addedContentObserver: NSObjectProtocol!

  #if DEBUG
  private static var signalSource: DispatchSourceSignal?
//  private var signalOnceToken = dispatch_once_t()
  private static let signalOnce: Void = {
    let queue = DispatchQueue.main;
    PhotoCollectionViewController.signalSource = DispatchSource.makeSignalSource(signal: 0, queue: queue);
    if let source = PhotoCollectionViewController.signalSource {
      source.setEventHandler{
        print("Hi, I am: \()")
      }
    }
    
  }()
  #endif

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

//    #if DEBUG // 1
//    dispatch_once(&signalOnceToken) { // 2
//      let queue = dispatch_get_main_queue()
//      self.signalSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL,
//        UInt(SIGSTOP), 0, queue) // 3
//      if let source = self.signalSource { // 4
//        dispatch_source_set_event_handler(source) { // 5
//          NSLog("Hi, I am: \(self.description)")
//        }
//        dispatch_resume(source) // 6
//      }
      
    
      
//    }
//    #endif

    library = ALAssetsLibrary()

    // Background image setup
    let backgroundImageView = UIImageView(image: UIImage(named:"background"))
    backgroundImageView.alpha = BackgroundImageOpacity
    backgroundImageView.contentMode = .center
    collectionView?.backgroundView = backgroundImageView

    contentUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PhotoManagerContentUpdateNotification),
      object: nil,
      queue: OperationQueue.main) { notification in
        self.contentChangedNotification(notification)
    }
    addedContentObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PhotoManagerAddedContentNotification),
      object: nil,
      queue: OperationQueue.main) { notification in
        self.contentChangedNotification(notification)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    showOrHideNavPrompt()
  }

  deinit {
    let nc = NotificationCenter.default
    if contentUpdateObserver != nil {
      nc.removeObserver(contentUpdateObserver)
    }
    if addedContentObserver != nil {
      nc.removeObserver(addedContentObserver)
    }
  }
}

// MARK: - UICollectionViewDataSource

private let PhotoCollectionCellID = "photoCell"

extension PhotoCollectionViewController {
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return PhotoManager.sharedManager.photos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionCellID, for: indexPath) 

    let imageView = cell.viewWithTag(CellImageViewTag) as! UIImageView
    let photoAssets = PhotoManager.sharedManager.photos
    let photo = photoAssets[(indexPath as NSIndexPath).row]

    switch photo.status {
    case .goodToGo:
      imageView.image = photo.thumbnail
    case .downloading:
      imageView.image = UIImage(named: "photoDownloading")
    case .failed:
      imageView.image = UIImage(named: "photoDownloadError")
    }

    return cell
  }
}

// MARK: - UICollectionViewDelegate

extension PhotoCollectionViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let photos = PhotoManager.sharedManager.photos
    let photo = photos[(indexPath as NSIndexPath).row]

    switch photo.status {
    case .goodToGo:
      let detailController = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController
      if let detailController = detailController {
        detailController.image = photo.image
        navigationController?.pushViewController(detailController, animated: true)
      }

    case .downloading:
      let alert = UIAlertController(title: "Downloading",
        message: "The image is currently downloading",
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      present(alert, animated: true, completion: nil)

    case .failed:
      let alert = UIAlertController(title: "Image Failed",
        message: "The image failed to be created",
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      present(alert, animated: true, completion: nil)
    }
  }
}

// MARK: - ELCImagePickerControllerDelegate

extension PhotoCollectionViewController: ELCImagePickerControllerDelegate {
  /**
   * Called with the picker the images were selected from, as well as an array of dictionary's
   * containing keys for ALAssetPropertyLocation, ALAssetPropertyType, 
   * UIImagePickerControllerOriginalImage, and UIImagePickerControllerReferenceURL.
   * @param picker
   * @param info An NSArray containing dictionary's with the key UIImagePickerControllerOriginalImage, which is a rotated, and sized for the screen 'default representation' of the image selected. If you want to get the original image, use the UIImagePickerControllerReferenceURL key.
   */
  public func elcImagePickerController(_ picker: ELCImagePickerController!, didFinishPickingMediaWithInfo info: [Any]!) {
    for dictionary in info as! [NSDictionary] {
      library.asset(for: dictionary[UIImagePickerControllerReferenceURL] as! URL, resultBlock: {
        asset in
        let photo = AssetPhoto(asset: asset!)
        PhotoManager.sharedManager.addPhoto(photo)
      },
      failureBlock: {
        error in
        let alert = UIAlertController(title: "Permission Denied",
          message: "To access your photos, please change the permissions in Settings",
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
      })
    }

    if Utils.userInterfaceIdiomIsPad {
      popController?.dismiss(animated: true)
    } else {
      dismiss(animated: true, completion: nil)
    }
  }

  func elcImagePickerControllerDidCancel(_ picker: ELCImagePickerController!) {
    if Utils.userInterfaceIdiomIsPad {
      popController?.dismiss(animated: true)
    } else {
      dismiss(animated: true, completion: nil)
    }
  }
}

// MARK: - IBAction Methods

extension PhotoCollectionViewController {
  // The upper right UIBarButtonItem method
  @IBAction func addPhotoAssets(_ sender: AnyObject!) {
    // Close popover if it is visible
    if popController?.isPopoverVisible == true {
      popController.dismiss(animated: true)
      popController = nil
      return
    }

    let alert = UIAlertController(title: "Get Photos From:", message: nil, preferredStyle: .actionSheet)

    // Cancel button
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alert.addAction(cancelAction)

    // Photo library button
    let libraryAction = UIAlertAction(title: "Photo Library", style: .default) {
      action in
      let imagePickerController = ELCImagePickerController()
      imagePickerController.imagePickerDelegate = self

      if Utils.userInterfaceIdiomIsPad {
        self.popController.dismiss(animated: true)
        self.popController = UIPopoverController(contentViewController: imagePickerController)
        self.popController.present(from: self.navigationItem.rightBarButtonItem!, permittedArrowDirections: .any, animated: true)
      } else {
        self.present(imagePickerController, animated: true, completion: nil)
      }
    }
    alert.addAction(libraryAction)

    // Internet button
    let internetAction = UIAlertAction(title: "Le Internet", style: .default) {
      action in
      self.downloadImageAssets()
    }
    alert.addAction(internetAction)

    if Utils.userInterfaceIdiomIsPad {
      popController = UIPopoverController(contentViewController: alert)
      popController.present(from: navigationItem.rightBarButtonItem!, permittedArrowDirections: .any, animated: true)
    } else {
      present(alert, animated: true, completion: nil)
    }
  }
}

// MARK: - Private Methods

private extension PhotoCollectionViewController {
  func contentChangedNotification(_ notification: Notification!) {
    collectionView?.reloadData()
    showOrHideNavPrompt();
  }

  func showOrHideNavPrompt() {
    let delayInSeconds = 1.0
    let popTime = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) // 1
    GlobalMainQueue.asyncAfter(deadline: popTime) { // 2
      let count = PhotoManager.sharedManager.photos.count
      if count > 0 {
        self.navigationItem.prompt = nil
      } else {
        self.navigationItem.prompt = "Add photos with faces to Googlyify them!"
      }
    }
  }

  func downloadImageAssets() {
    PhotoManager.sharedManager.downloadPhotosWithCompletion() {
      error in
      // This completion block currently executes at the wrong time
      let message = error?.localizedDescription ?? "The images have finished downloading"
      let alert = UIAlertController(title: "Download Complete", message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }
}
