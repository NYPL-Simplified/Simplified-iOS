//
//  NYPLDeviceManager.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 1/12/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLDeviceManager: NSObject {
  
  private class var authorizationHeader: String
  {
    let authenticationString = "\(NYPLAccount.shared().barcode!):\(NYPLAccount.shared().pin!)"
    let authenticationData:Data = authenticationString.data(using: String.Encoding.ascii)!
    let authenticationValue = "Basic \(authenticationData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)))"
    
    return "\(authenticationValue)"
  }
  private class var contentTypeHeader: String
  {
    return "vnd.librarysimplified/drm-device-id-list"
  }
  
  class func postDevice(_ deviceID:String, url:URL)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      Log.info(#file, "device: \(deviceID)")

      let body = deviceID.data(using: String.Encoding.utf8)!
      postRequest(url, body, authorizationHeader, contentTypeHeader)
    }
  }
  
  class func deleteDevice(_ deviceID:String, url:URL)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      Log.info(#file, "device: \(deviceID)")

      var deleteUrl:URL = url
      deleteUrl.appendPathComponent(deviceID)
      deleteRequest(deleteUrl, authorizationHeader, contentTypeHeader)
    }
  }
  
  
  private class func postRequest(_ url: URL, _ body: Data, _ authHeader: String?, _ contentType: String?)
  {
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = body
    if let value = authHeader {
      request.setValue(value, forHTTPHeaderField: "Authorization")
    }
    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        Log.info(#file, "POST device: Success")
      } else {
        guard let error = error as? NSError else { return }
        if
          OfflineQueueStatusCodes.contains(error.code) {
          Log.info(#file, "POST device: Response Error: \(error.localizedDescription)")
        }
      }
    }
    
    task.resume()
  }
  
  private class func deleteRequest(_ url: URL, _ authHeader: String?, _ contentType: String?)
  {
    
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    if let value = authHeader {
      request.setValue(value, forHTTPHeaderField: "Authorization")
    }
    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        Log.info(#file, "DELETE device: Success")
      } else {
        guard let error = error as? NSError else { return }
        if OfflineQueueStatusCodes.contains(error.code) {
          Log.error(#file, "DELETE device: Response Error: \(error.localizedDescription)")
        }
      }
    }
    
    task.resume()
  }
  
}

