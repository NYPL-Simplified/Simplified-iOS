import Foundation

let DownloadingKey = "downloading"
let DownloadFailedKey = "download-failed"
let DownloadNeededKey = "download-needed"
let DownloadSuccessfulKey = "download-successful"
let UnregisteredKey = "unregistered"
let HoldingKey = "holding"
let UsedKey = "used"
let UnsupportedKey = "unsupported"

@objc public enum NYPLBookState : Int {
  case Unregistered = 0
  case DownloadNeeded = 1
  case Downloading
  case DownloadFailed
  case DownloadSuccessful
  case Holding
  case Used
  case Unsupported
    
  init?(_ stringValue: String) {
    switch stringValue {
      case DownloadingKey:
        self = .Downloading
      case DownloadFailedKey:
        self = .DownloadFailed
      case DownloadNeededKey:
        self = .DownloadNeeded
      case DownloadSuccessfulKey:
        self = .DownloadSuccessful
      case UnregisteredKey:
        self = .Unregistered
      case HoldingKey:
        self = .Holding
      case UsedKey:
        self = .Used
      case UnsupportedKey:
        self = .Unsupported
      default:
        return nil
    }
  }
    
  func stringValue() -> String {
    switch self {
      case .Downloading:
        return DownloadingKey;
      case .DownloadFailed:
        return DownloadFailedKey;
      case .DownloadNeeded:
        return DownloadNeededKey;
      case .DownloadSuccessful:
        return DownloadSuccessfulKey;
      case .Unregistered:
        return UnregisteredKey;
      case .Holding:
        return HoldingKey;
      case .Used:
        return UsedKey;
      case .Unsupported:
        return UnsupportedKey;
    }
  }
}

// For Objective-C, since Obj-C enum is not allowed to have methods
// TODO: Remove when migration to Swift completed
@objcMembers class NYPLBookStateHelper : NSObject {
  static func getString(from state: NYPLBookState) -> String {
    return state.stringValue()
  }
    
  static func getState(from string: String) -> Int {
    return NYPLBookState.init(string)?.rawValue ?? -1
  }
}

