//
//  NYPLAxisLibraryService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

class NYPLFullAxisNowResource: TransformingResource {
  
  private let resourceTransformAdapter: NYPLFullAxisNowResourceAdapter
  
  init(adapter: NYPLFullAxisNowResourceAdapter, resource: Resource) {
    self.resourceTransformAdapter = adapter
    super.init(resource)
  }
  
  /// Decrypts the given resource uusing the NYPLFullAxisNowResourceAdapter which uses the `AES`
  /// key obtained from the license. Returns original resource if not encrypted or if failure occurs during
  /// decrypting.
  override func transform(_ data: ResourceResult<Data>) -> ResourceResult<Data> {
    return resourceTransformAdapter.transform(data)
  }
  
  override var length: ResourceResult<UInt64> {
    // Uses `originalLength` or falls back on the actual decrypted data length.
    resource.link.properties.encryption?.originalLength.map { .success(UInt64($0)) }
      ?? super.length
  }
  
}

