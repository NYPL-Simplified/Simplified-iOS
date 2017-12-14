import UIKit

/// Manage Activation ID's created by Adobe by removing or saving them to our server.
/// These ID's can be commonly lost if a user deletes SimplyE, updates between
/// a beta and the production version, or through other ways we're not aware of.
/// We may be able to recover (from the 6 allowed) activations by sending these
/// through the deactivation process in the black box manually.
class NYPLDeviceManager: NSObject {
  
  private static let contentTypeHeader = "vnd.librarysimplified/drm-device-id-list"
  
  class func postDevice(_ deviceID:String, url:URL) {
    if (NYPLAccount.shared().hasBarcodeAndPIN()) {
      Log.debug(#file, "Adding New Activation Device ID: \(deviceID)")
      if let body = deviceID.data(using: String.Encoding.utf8) {
        addDeviceNetworkRequest(url, body, contentTypeHeader)
      } else {
        Log.error(#file, "Could not generate data class from device ID.")
      }
    }
  }
  
  class func deleteDevice(_ deviceID:String, url:URL) {
    if (NYPLAccount.shared().hasBarcodeAndPIN()) {
      Log.debug(#file, "Removing Activation Device ID: \(deviceID)")
      var deleteUrl:URL = url
      deleteUrl.appendPathComponent(deviceID)
      deleteDeviceNetworkRequest(deleteUrl, contentTypeHeader)
    }
  }
  
  
  private class func addDeviceNetworkRequest(_ url: URL, _ body: Data, _ contentType: String?) {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = body
    NYPLAnnotations.setDefaultAnnotationHeaders(forRequest: &request)

    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error as NSError? {
        Log.error(#file, "Request Error: \(error.code). Description: \(error.localizedDescription)")
        return
      }
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        Log.debug(#file, "POST request: Success")
      } else {
        guard let error = error as NSError? else { return }
        Log.debug(#file, "POST request: Response Error: \(error.localizedDescription)")
      }
    }
    task.resume()
  }
  
  private class func deleteDeviceNetworkRequest(_ url: URL, _ contentType: String?) {
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    NYPLAnnotations.setDefaultAnnotationHeaders(forRequest: &request)

    if let value = contentType {
      request.setValue(value, forHTTPHeaderField: "Content-Type")
    }
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error as NSError? {
        Log.error(#file, "Request Error: \(error.code). Description: \(error.localizedDescription)")
        return
      }
      guard let response = response as? HTTPURLResponse else { return }
      if response.statusCode == 200 {
        Log.debug(#file, "DELETE request: Success")
      } else {
        guard let error = error as NSError? else { return }
        Log.error(#file, "DELETE request: Response Error: \(error.localizedDescription)")
      }
    }
    
    task.resume()
  }
  
}

