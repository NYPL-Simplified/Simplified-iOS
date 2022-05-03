import Foundation

let DownloadingKey = "downloading"
let DownloadFailedKey = "download-failed"
let DownloadNeededKey = "download-needed"
let DownloadSuccessfulKey = "download-successful"
let UnregisteredKey = "unregistered"
let HoldingKey = "holding"
let UsedKey = "used"
let UnsupportedKey = "unsupported"
let SAMLStartedKey = "saml-started"
let DownloadingUsableKey = "downloading-usable"

@objc public enum NYPLBookState : Int, CaseIterable {
  case Unregistered = 0
  case DownloadNeeded = 1
  case Downloading
  case DownloadFailed
  case DownloadSuccessful
  case Holding
  case Used
  case Unsupported
  // This state means that user is logged using SAML environment and app begun download process, but didn't transition to download center yet
  case SAMLStarted
  // This state is designated for audiobook that is downloading in background but ready to listen.
  // It should be treated as DownloadSuccessful for business related logic,
  // and treated as Downloading for UI update.
  case DownloadingUsable

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
      case SAMLStartedKey:
        self = .SAMLStarted
      case DownloadingUsableKey:
        self = .DownloadingUsable
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
      case .SAMLStarted:
        return SAMLStartedKey;
      case .DownloadingUsable:
        return DownloadingUsableKey
    }
  }
}

// For Objective-C, since Obj-C enum is not allowed to have methods
// TODO: Remove when migration to Swift completed
class NYPLBookStateHelper : NSObject {
  @objc(stringValueFromBookState:)
  static func stringValue(from state: NYPLBookState) -> String {
    return state.stringValue()
  }
    
  @objc(bookStateFromString:)
  static func bookState(fromString string: String) -> NSNumber? {
    guard let state = NYPLBookState(string) else {
      return nil
    }

    return NSNumber(integerLiteral: state.rawValue)
  }
    
  @objc static func allBookStates() -> [NYPLBookState.RawValue] {
    return NYPLBookState.allCases.map{ $0.rawValue }
  }
}

