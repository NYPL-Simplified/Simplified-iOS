//
//  NYPLBook+Additions.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 7/9/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

extension NYPLBook {
  /// An informative short string describing the book, for logging purposes.
  @objc func loggableShortString() -> String {
    return "<\(title ?? "")` ID=\(identifier ?? "") Distributor=\(distributor ?? "")>"
  }

  /// An informative dictionary detailing all aspects of the book that could
  /// be interesting for logging purposes.
  @objc func loggableDictionary() -> [String: Any] {
    let acquisitions = self.acquisitions.compactMap {
      $0.dictionaryRepresentation()
    }

    return [
      "bookTitle": title ?? "",
      "bookID": identifier ?? "",
      "bookDistributor": distributor ?? "",
      "acquisitions": acquisitions,
      "alternateURL": alternateURL ?? "N/A",
      "contentType": NYPLBookContentTypeConverter.stringValue(of: defaultBookContentType())
    ]
  }
}
