//
//  NYPLDeviceManager.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 1/12/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLDeviceManager: NSObject {
  
  private class var contentTypeHeader: String
  {
    return "vnd.librarysimplified/drm-device-id-list"
  }
  
  class func postDevice(_ deviceID:String, url:URL)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      debugPrint(#file, "device: \(deviceID)")

      let body = deviceID.data(using: String.Encoding.utf8)!
      postRequest(url, body, NYPLAnnotations.headers, contentTypeHeader)
    }
  }
  
  class func deleteDevice(_ deviceID:String, url:URL)
  {
    if (NYPLAccount.shared().hasBarcodeAndPIN())
    {
      debugPrint(#file, "device: \(deviceID)")

      var deleteUrl:URL = url
      deleteUrl.appendPathComponent(deviceID)
      deleteRequest(deleteUrl, NYPLAnnotations.headers, contentTypeHeader)
    }
  }
  
  
  private class func postRequest(_ url: URL, _ body: Data, _ headers: [String:String]?, _ contentType: String?)
  {
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = body
    
    if let headers = headers {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        debugPrint(#file, "POST device: Success")
      } else {
        guard let error = error as? NSError else { return }
        debugPrint(#file, "POST device: Response Error: \(error.localizedDescription)")
      }
    }
    
    task.resume()
  }
  
  private class func deleteRequest(_ url: URL, _ headers: [String:String]?, _ contentType: String?)
  {
    
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    
    if let headers = headers {
      for (headerKey, headerValue) in headers {
        request.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        debugPrint(#file, "DELETE device: Success")
      } else {
        guard let error = error as? NSError else { return }
        Log.error(#file, "DELETE device: Response Error: \(error.localizedDescription)")
      }
    }
    
    task.resume()
  }
  
}

