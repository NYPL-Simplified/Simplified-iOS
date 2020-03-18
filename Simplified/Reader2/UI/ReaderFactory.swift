//
//  ReaderFactory.swift
//  r2-testapp-swift
//
//  Created by Mickaël Menu on 22.02.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import R2Shared


final class ReaderFactory {

  private final class Storyboards {
    let outline = UIStoryboard(name: "Outline", bundle: nil)
  }

  private let storyboards = Storyboards()

  func makeTOCVC(for publication: Publication) -> OutlineTableViewController {
    let controller = storyboards.outline.instantiateViewController(withIdentifier: "OutlineTableViewController") as! OutlineTableViewController
    controller.publication = publication
    return controller
  }
}

