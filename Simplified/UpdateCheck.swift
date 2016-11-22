import Foundation

final class UpdateCheck {
  
  /// A structure for representing a SemVer 2.0 version.
  struct Version: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    
    /// @return (major, minor, patch)
    func tuple() -> (Int, Int, Int) {
      return (self.major, self.minor, self.patch)
    }
  }
  
  enum Result {
    case upToDate
    case needsUpdate(minimumVersion: Version, updateURL: URL)
    case unknown
  }
  
  /// @param string A string in SemVer 2.0 format.
  ///
  /// @result A `Version`, else `nil` if the input cannot be parsed or exceeds 255 characters.
  fileprivate static func parseVersionString(_ string: String) -> Version? {
    if string.lengthOfBytes(using: String.Encoding.utf8) >= 255 {
      return nil
    }
    
    let components = string.components(separatedBy: ".")
    guard components.count == 3 else {
      return nil
    }
    
    guard
      let major = Int(components[0]),
      let minor = Int(components[1]),
      let patch = Int(components[2]) else
    {
      return nil
    }
    
    return Version(major: major, minor: minor, patch: patch)
  }
  
  /// @param minimumVersionURL An `NSURL` pointing to JSON data of the following format:
  /// {"iOS" = {"minimum-version" = "1.0.0", "update-url" = "http://example.com"}, …}
  ///
  /// @param handler A handler that will be called on an arbitrary thread.
  static func performUpdateCheck(_ minimumVersionURL: URL, handler: @escaping (Result) -> Void) {
    
    let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    defer {
      session.finishTasksAndInvalidate()
    }
    
    let task = session.dataTask(with: minimumVersionURL, completionHandler: {(data, response, error) in
      if minimumVersionURL.scheme == "http" || minimumVersionURL.scheme == "https" {
        guard response != nil else {
          Log.debug(#file, "No response when requesting minimum version document.")
          handler(.unknown)
          return
        }
        let HTTPResponse = response as! HTTPURLResponse
        switch HTTPResponse.statusCode {
        case 200:
          break
        case 404:
          // A 404 indicates that there is no minimum version required, thus all is well.
          Log.debug(#file, "Received 404 when requesting minimum version document.")
          handler(.unknown)
          return
        default:
          Log.info(#file, "Ignoring response with unexpected status code \(HTTPResponse.statusCode).")
          handler(.unknown)
          return
        }
      }
      
      guard let data = data else {
        Log.info(#file, "Ignoring response with no data.")
        handler(.unknown)
        return
      }
      guard let JSON = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        as! [String: AnyObject] else
      {
        Log.info(#file, "Unable to parse JSON response.")
        handler(.unknown)
        return
      }
      guard
        let iOS = JSON["iOS"] as? [String: AnyObject],
        let minimumVersionString = iOS["minimum-version"] as? String,
        let updateURLString = iOS["update-url"] as? String else
      {
        Log.info(#file, "Invalid JSON response.")
        handler(.unknown)
        return
      }
      guard let minimumVersion = parseVersionString(minimumVersionString) else {
        Log.info(#file, "Invalid version string.")
        handler(.unknown)
        return
      }
      guard let updateURL = URL.init(string: updateURLString) else {
        Log.info(#file, "Invalid update URL.")
        handler(.unknown)
        return
      }
      let currentVersionString =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
      let currentVersion = parseVersionString(currentVersionString)!
      if(currentVersion >= minimumVersion) {
        handler(.upToDate)
      } else {
        handler(.needsUpdate(minimumVersion: minimumVersion, updateURL: updateURL))
      }
    }) 
    
    task.resume()
  }
}

func ==(a: UpdateCheck.Version, b: UpdateCheck.Version) -> Bool {
  return a.tuple() == b.tuple()
}

func <(a: UpdateCheck.Version, b: UpdateCheck.Version) -> Bool {
  return a.tuple() < b.tuple()
}

func <=(a: UpdateCheck.Version, b: UpdateCheck.Version) -> Bool {
  return a.tuple() <= b.tuple()
}

func >(a: UpdateCheck.Version, b: UpdateCheck.Version) -> Bool {
  return a.tuple() > b.tuple()
}

func >=(a: UpdateCheck.Version, b: UpdateCheck.Version) -> Bool {
  return a.tuple() >= b.tuple()
}
