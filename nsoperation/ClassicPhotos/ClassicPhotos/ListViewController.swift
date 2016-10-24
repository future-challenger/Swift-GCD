//
//  ListViewController.swift
//  ClassicPhotos
//
//  Created by Richard Turton on 03/07/2014.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit
import CoreImage

let dataSourceURL = URL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class ListViewController: UITableViewController {
  
  //lazy var photos = NSDictionary(contentsOf:dataSourceURL!)!
  var photos = [PhotoRecord]()
  let pendingOperations = PendingOperations()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // #pragma mark - Table view data source
  
  override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
    
    if cell.accessoryView == nil {
      let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      cell.accessoryView = indicator
    }
    
    let indicator = cell.accessoryView as! UIActivityIndicatorView
    
    let photoDetails = photos[indexPath.row]
    
    cell.textLabel?.text = photoDetails.name
    cell.imageView?.image = photoDetails.image
    
    switch photoDetails.state {
    case .filtered:
      indicator.stopAnimating()
    case .failed:
      indicator.stopAnimating()
      cell.textLabel?.text = "Failed to load"
    case .new, .downloaded:
      indicator.startAnimating()
      
      if (!tableView.isDragging && !tableView.isDecelerating) {
        
        self.startOperationsForPhotoRecord(photoDetails, indexPath: (indexPath as NSIndexPath) as IndexPath)
      }
    }
    
    return cell
  }
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    suspendAllOperations()
  }
  
  override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      loadImagesforOnScreenCells()
      resumeAllOperations()
    }
  }
  
  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    loadImagesforOnScreenCells()
    resumeAllOperations()
  }
  
  func suspendAllOperations () {
    pendingOperations.downloadQueue.isSuspended = true
    pendingOperations.filtrationQueue.isSuspended = true
  }
  
  func resumeAllOperations() {
    pendingOperations.downloadQueue.isSuspended = false
    pendingOperations.filtrationQueue.isSuspended = false
  }
  
  func loadImagesforOnScreenCells() {
    if let pathsArray = tableView.indexPathsForVisibleRows {
      
      let allPendingOperations = Set(pendingOperations.downloadInProgress.keys)
      allPendingOperations.union(pendingOperations.filtrationsInProgress.keys)
      
      var toBeCancelled = allPendingOperations
      let visiblePaths = Set(pathsArray as [NSIndexPath])
      toBeCancelled.subtract(visiblePaths as Set<IndexPath>)
      
      var toBeStarted = visiblePaths
      toBeStarted.subtract(allPendingOperations as Set<NSIndexPath>)
      
      for indexPath in toBeCancelled {
        
        if let pendingDownload = pendingOperations.downloadInProgress[indexPath] {
          pendingDownload.cancel()
        }
        
        pendingOperations.downloadInProgress.removeValue(forKey: indexPath)
        
        if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
          pendingFiltration.cancel()
        }
        
        pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
      }
      
      for indexPath in toBeStarted {
        let indexPath = indexPath as NSIndexPath
        let recordToProcess = self.photos[indexPath.row]
        startOperationsForPhotoRecord(recordToProcess, indexPath: indexPath as IndexPath)
      }
    }
  }
  
  func startOperationsForPhotoRecord(_ photoDetails: PhotoRecord, indexPath: IndexPath) {
    
    switch photoDetails.state {
    case .new:
      startDownloadforRecord(photoDetails, indexPath: indexPath)
    case .downloaded:
      startFiltrationForRecord(photoDetails, indexPath: indexPath)
    default:
      print("None.")
    }
    
  }
  
  func startDownloadforRecord(_ photoDetails: PhotoRecord, indexPath: IndexPath) {
    if pendingOperations.downloadInProgress[indexPath] != nil {
      return
    }
    
    let downloader = ImageDownloader(photoRecord: photoDetails)
    
    downloader.completionBlock = {
      
      if downloader.isCancelled {
        return
      }
      
      DispatchQueue.main.async(execute: {
        self.pendingOperations.downloadInProgress.removeValue(forKey: indexPath)
        self.tableView.reloadRows(at: [indexPath as IndexPath], with: .fade)
      })
      
    }
    
    pendingOperations.downloadInProgress[indexPath] = downloader
    
    pendingOperations.downloadQueue.addOperation(downloader)
    
  }
  
  func startFiltrationForRecord(_ photoDetails: PhotoRecord, indexPath: IndexPath) {
    
    if pendingOperations.filtrationsInProgress[indexPath] != nil {
      return
    }
    
    let filterer = ImageFiltration(photoRecord: photoDetails)
    
    filterer.completionBlock = {
      
      if filterer.isCancelled {
        return
      }
      
      DispatchQueue.main.async(execute: {
        self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
        self.tableView.reloadRows(at: [indexPath as IndexPath], with: .fade)
      })
      
      
    }
    
    pendingOperations.filtrationsInProgress[indexPath] = filterer
    pendingOperations.filtrationQueue.addOperation(filterer)
  }
  
  func fetchPhotoDetails() {
    
    let request = URLRequest(url: dataSourceURL!)
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    
    let session: URLSession = URLSession.shared
    
    let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
      
      guard error == nil else {
        let alert = UIAlertView(title: "Error", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Okay")
        alert.show()
        return
      }
      
      
      var datasourceDictionary: Dictionary <String, String>?
      
      do {
        datasourceDictionary = try PropertyListSerialization.propertyList(from: data!, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? Dictionary
      } catch {
        print("Something went wrong!")
      }
      
      for(key, value) in datasourceDictionary! {
        
        let name = key
        let url = URL(string: value )
        
        print("\(name) ==> \(url?.description)")
        if url != nil {
          let photoRecord = PhotoRecord(name: name, url: url!)
          self.photos.append(photoRecord)
        }
      }
      
      self.tableView.reloadData()
    }
    
    task.resume()
    
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
}
