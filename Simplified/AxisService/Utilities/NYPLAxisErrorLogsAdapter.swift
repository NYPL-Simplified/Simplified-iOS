//
//  NYPLAxisErrorLogsAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis

struct NYPLAxisErrorLogsAdapter: NYPLAxisErrorLogging {
  func logError(_ error: Error?, summary: String, metadata: [String : Any]?) {
    NYPLErrorLogger.logError(error, summary: summary, metadata: metadata)
  }
  
  func logError(withCode code: NYPLAxisErrorCode, summary: String, metadata: [String : Any]?) {
    NYPLErrorLogger.logError(withCode: code.toNYPLErrorCode, summary: summary, metadata: metadata)
  }
  
}

private extension NYPLAxisErrorCode {
  var toNYPLErrorCode: NYPLErrorCode {
    switch self {
    case .axisDRMFulfillmentFail: return .axisDRMFulfillmentFail
    case .axisCryptographyFail: return .axisCryptographyFail
    }
  }
}
