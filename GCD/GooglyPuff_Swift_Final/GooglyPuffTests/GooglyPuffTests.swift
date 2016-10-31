//
//  GooglyPuffTests.swift
//  GooglyPuffTests
//
//  Created by Bjørn Olav Ruud on 06.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import UIKit
import XCTest

private let DefaultTimeoutLengthInNanoSeconds: Int64 = 10000000000 // 10 Seconds

class GooglyPuffTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testMikeAshImageURL() {
    downloadImageURLWithString(LotsOfFacesURLString)
  }

  func testMattThompsonImageURL() {
    downloadImageURLWithString(SuccessKidURLString)
  }

  func testAaronHillegassImageURL() {
    downloadImageURLWithString(OverlyAttachedGirlfriendURLString)
  }

  func downloadImageURLWithString(_ urlString: String) {
    let url = URL(string: urlString)
    let downloadExpectation = expectation(description: "Image downloaded from \(urlString)") // 1
    let photo = DownloadPhoto(url: url!) {
      image, error in
      if let error = error {
        XCTFail("\(urlString) failed. \(error.localizedDescription)")
      }
      downloadExpectation.fulfill() // 2
    }

    waitForExpectations(timeout: 10) { // 3
      error in
      if let error = error {
        XCTFail(error.localizedDescription)
      }
    }
  }

}
