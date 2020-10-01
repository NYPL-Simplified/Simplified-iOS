
private let userAboveAgeKey              = "NYPLSettingsUserAboveAgeKey"
private let accountSyncEnabledKey        = "NYPLAccountSyncEnabledKey"

/// This class is used for mapping details of SAML Identity Provider received in authentication document
@objcMembers
class OPDS2SamlIDP: NSObject, Codable {
  /// url to begin SAML login process with a given IDP
  let url: URL

  private let displayNames: [String: String]?
  private let descriptions: [String: String]?

  var displayName: String? { displayNames?["en"] }
  var idpDescription: String? { descriptions?["en"] }

  init?(opdsLink: OPDS2Link) {
    guard let url = URL(string: opdsLink.href) else { return nil }
    self.url = url
    self.displayNames = opdsLink.displayNames?.reduce(into: [String: String]()) { $0[$1.language] = $1.value }
    self.descriptions = opdsLink.descriptions?.reduce(into: [String: String]()) { $0[$1.language] = $1.value }
  }
}

@objc protocol NYPLSignedInStateProvider {
  func isSignedIn() -> Bool
}

// MARK: AccountDetails
// Extra data that gets loaded from an OPDS2AuthenticationDocument,
@objcMembers final class AccountDetails: NSObject {
  enum AuthType: String, Codable {
    case basic = "http://opds-spec.org/auth/basic"
    case coppa = "http://librarysimplified.org/terms/authentication/gate/coppa"
    case anonymous = "http://librarysimplified.org/rel/auth/anonymous"
    case oauthIntermediary = "http://librarysimplified.org/authtype/OAuth-with-intermediary"
    case saml = "http://librarysimplified.org/authtype/SAML-2.0"
    case none
  }
  
  @objc(AccountDetailsAuthentication)
  @objcMembers
  class Authentication: NSObject, Codable, NSCoding {
    let authType:AuthType
    let authPasscodeLength:UInt
    let patronIDKeyboard:LoginKeyboard
    let pinKeyboard:LoginKeyboard
    let patronIDLabel:String?
    let pinLabel:String?
    let supportsBarcodeScanner:Bool
    let supportsBarcodeDisplay:Bool
    let coppaUnderUrl:URL?
    let coppaOverUrl:URL?
    let oauthIntermediaryUrl:URL?
    let methodDescription: String?

    let samlIdps: [OPDS2SamlIDP]?

    init(auth: OPDS2AuthenticationDocument.Authentication) {
      let authType = AuthType(rawValue: auth.type) ?? .none
      self.authType = authType
      authPasscodeLength = auth.inputs?.password.maximumLength ?? 99
      patronIDKeyboard = LoginKeyboard.init(auth.inputs?.login.keyboard) ?? .standard
      pinKeyboard = LoginKeyboard.init(auth.inputs?.password.keyboard) ?? .standard
      patronIDLabel = auth.labels?.login
      pinLabel = auth.labels?.password
      methodDescription = auth.description
      supportsBarcodeScanner = auth.inputs?.login.barcodeFormat == "Codabar"
      supportsBarcodeDisplay = supportsBarcodeScanner

      switch authType {
      case .coppa:
        coppaUnderUrl = URL.init(string: auth.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/authentication/restriction-not-met" })?.href ?? "")
        coppaOverUrl = URL.init(string: auth.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/authentication/restriction-met" })?.href ?? "")
        oauthIntermediaryUrl = nil
        samlIdps = nil

      case .oauthIntermediary:
        oauthIntermediaryUrl = URL.init(string: auth.links?.first(where: { $0.rel == "authenticate" })?.href ?? "")
        coppaUnderUrl = nil
        coppaOverUrl = nil
        samlIdps = nil

      case .saml:
        samlIdps = auth.links?.filter { $0.rel == "authenticate" }.compactMap { OPDS2SamlIDP(opdsLink: $0) }
        oauthIntermediaryUrl = nil
        coppaUnderUrl = nil
        coppaOverUrl = nil

      case .none, .basic, .anonymous:
        oauthIntermediaryUrl = nil
        coppaUnderUrl = nil
        coppaOverUrl = nil
        samlIdps = nil

      }
    }

    var needsAuth:Bool {
      return authType == .basic || authType == .oauthIntermediary || authType == .saml
    }

    var needsAgeCheck:Bool {
      return authType == .coppa
    }

    func coppaURL(isOfAge: Bool) -> URL? {
      isOfAge ? coppaOverUrl : coppaUnderUrl
    }

    // use for Objective-C only, authType is the prefered way to do it in Swift
    var isOauth: Bool {
      return authType == .oauthIntermediary
    }

    // use for Objective-C only, authType is the prefered way to do it in Swift
    var isSaml: Bool {
      return authType == .saml
    }

    /// secured catalog would require user to log in prior to accessing it
    var isCatalogSecured: Bool {
      // you need an oauth token in order to access catalogs if authentication type is either oauth with intermediary (ex. Clever), or SAML
      return authType == .oauthIntermediary || authType == .saml
    }

    func encode(with coder: NSCoder) {
      let jsonEncoder = JSONEncoder()
      guard let data = try? jsonEncoder.encode(self) else { return }
      coder.encode(data as NSData)
    }

    required init?(coder: NSCoder) {
      guard let data = coder.decodeData() else { return nil }
      let jsonDecoder = JSONDecoder()
      guard let authentication = try? jsonDecoder.decode(Authentication.self, from: data) else { return nil }

      authType = authentication.authType
      authPasscodeLength = authentication.authPasscodeLength
      patronIDKeyboard = authentication.patronIDKeyboard
      pinKeyboard = authentication.pinKeyboard
      patronIDLabel = authentication.patronIDLabel
      pinLabel = authentication.pinLabel
      supportsBarcodeScanner = authentication.supportsBarcodeScanner
      supportsBarcodeDisplay = authentication.supportsBarcodeDisplay
      coppaUnderUrl = authentication.coppaUnderUrl
      coppaOverUrl = authentication.coppaOverUrl
      oauthIntermediaryUrl = authentication.oauthIntermediaryUrl
      methodDescription = authentication.methodDescription
      samlIdps = authentication.samlIdps
    }
  }

  let defaults:UserDefaults
  let uuid:String
  let supportsSimplyESync:Bool
  let supportsCardCreator:Bool
  let supportsReservations:Bool
  let auths: [Authentication]

  let mainColor:String?
  let userProfileUrl:String?
  let signUpUrl:URL?
  let loansUrl:URL?
  var defaultAuth: Authentication? {
    guard auths.count > 1 else { return auths.first }
    return auths.first(where: { !$0.isCatalogSecured }) ?? auths.first
  }
  var needsAgeCheck: Bool {
    // this will tell if any authentication method requires age check
    return auths.reduce(false) { $0 || $1.needsAgeCheck }
  }

  fileprivate var urlAnnotations:URL?
  fileprivate var urlAcknowledgements:URL?
  fileprivate var urlContentLicenses:URL?
  fileprivate var urlEULA:URL?
  fileprivate var urlPrivacyPolicy:URL?
  
  var eulaIsAccepted:Bool {
    get {
      guard let result = getAccountDictionaryKey(NYPLSettings.userHasAcceptedEULAKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(NYPLSettings.userHasAcceptedEULAKey,
                              toValue: newValue as AnyObject)
    }
  }
  var syncPermissionGranted:Bool {
    get {
      guard let result = getAccountDictionaryKey(accountSyncEnabledKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(accountSyncEnabledKey, toValue: newValue as AnyObject)
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAboveAgeKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAboveAgeKey, toValue: newValue as AnyObject)
    }
  }
  
  init(authenticationDocument: OPDS2AuthenticationDocument, uuid: String) {
    defaults = .standard
    self.uuid = uuid

    auths = authenticationDocument.authentication?.map({ (opdsAuth) -> Authentication in
      return Authentication.init(auth: opdsAuth)
    }) ?? []

//    // TODO: Code below will remove all oauth only auth methods, this behaviour wasn't tested though
//    // and may produce undefined results in viewcontrollers that do present auth methods if none are available
//    auths = authenticationDocument.authentication?.map({ (opdsAuth) -> Authentication in
//      return Authentication.init(auth: opdsAuth)
//    }).filter { $0.authType != .oauthIntermediary } ?? []

    supportsReservations = authenticationDocument.features?.disabled?.contains("https://librarysimplified.org/rel/policy/reservations") != true
    userProfileUrl = authenticationDocument.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/user-profile" })?.href
    loansUrl = URL.init(string: authenticationDocument.links?.first(where: { $0.rel == "http://opds-spec.org/shelf" })?.href ?? "")
    supportsSimplyESync = userProfileUrl != nil
    
    mainColor = authenticationDocument.colorScheme
    
    let registerUrlStr = authenticationDocument.links?.first(where: { $0.rel == "register" })?.href
    if let registerUrlStr = registerUrlStr {
      let trimmedUrlStr = registerUrlStr.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedUrlStr.lowercased().hasPrefix("nypl.card-creator:") {
        let cartCreatorUrlStr = String(trimmedUrlStr.dropFirst("nypl.card-creator:".count))
        signUpUrl = URL(string: cartCreatorUrlStr)
        supportsCardCreator = (signUpUrl != nil)
      } else {
        // fallback to attempt to use the URL we got even though it doesn't
        // have the scheme we expected.
        signUpUrl = URL(string: trimmedUrlStr)
        supportsCardCreator = false
      }
    } else {
      signUpUrl = nil
      supportsCardCreator = false
    }
    
    super.init()
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "privacy-policy" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .privacyPolicy)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "terms-of-service" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .eula)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "license" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .contentLicenses)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "copyright" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .acknowledgements)
    }
  }

  func setURL(_ URL: URL, forLicense urlType: URLType) -> Void {
    switch urlType {
    case .acknowledgements:
      urlAcknowledgements = URL
      setAccountDictionaryKey("urlAcknowledgements", toValue: URL.absoluteString as AnyObject)
    case .contentLicenses:
      urlContentLicenses = URL
      setAccountDictionaryKey("urlContentLicenses", toValue: URL.absoluteString as AnyObject)
    case .eula:
      urlEULA = URL
      setAccountDictionaryKey("urlEULA", toValue: URL.absoluteString as AnyObject)
    case .privacyPolicy:
      urlPrivacyPolicy = URL
      setAccountDictionaryKey("urlPrivacyPolicy", toValue: URL.absoluteString as AnyObject)
    case .annotations:
      urlAnnotations = URL
      setAccountDictionaryKey("urlAnnotations", toValue: URL.absoluteString as AnyObject)
    }
  }
  
  func getLicenseURL(_ type: URLType) -> URL? {
    switch type {
    case .acknowledgements:
      if let url = urlAcknowledgements {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAcknowledgements") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .contentLicenses:
      if let url = urlContentLicenses {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlContentLicenses") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .eula:
      if let url = urlEULA {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlEULA") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .privacyPolicy:
      if let url = urlPrivacyPolicy {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlPrivacyPolicy") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .annotations:
      if let url = urlAnnotations {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAnnotations") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    }
  }
  
  fileprivate func setAccountDictionaryKey(_ key: String, toValue value: AnyObject) {
    if var savedDict = defaults.value(forKey: self.uuid) as? [String: AnyObject] {
      savedDict[key] = value
      defaults.set(savedDict, forKey: self.uuid)
    } else {
      defaults.set([key:value], forKey: self.uuid)
    }
  }
  
  fileprivate func getAccountDictionaryKey(_ key: String) -> AnyObject? {
    let savedDict = defaults.value(forKey: self.uuid) as? [String: AnyObject]
    guard let result = savedDict?[key] else { return nil }
    return result
  }
}

// MARK: Account
/// Object representing one library account in the app. Patrons may
/// choose to sign up for multiple Accounts.
@objcMembers final class Account: NSObject
{
  let logo:UIImage
  let uuid:String
  let name:String
  let subtitle:String?
  let supportEmail:String?
  let catalogUrl:String?
  var details:AccountDetails?
  
  let authenticationDocumentUrl:String?
  var authenticationDocument:OPDS2AuthenticationDocument? {
    didSet {
      guard let authenticationDocument = authenticationDocument else {
        return
      }
      details = AccountDetails(authenticationDocument: authenticationDocument, uuid: uuid)
    }
  }
  

  var loansUrl: URL? {
    return details?.loansUrl
  }
  
  init(publication: OPDS2Publication) {
    
    name = publication.metadata.title
    subtitle = publication.metadata.description
    uuid = publication.metadata.id
    
    catalogUrl = publication.links.first(where: { $0.rel == "http://opds-spec.org/catalog" })?.href
    supportEmail = publication.links.first(where: { $0.rel == "help" })?.href.replacingOccurrences(of: "mailto:", with: "")
    
    authenticationDocumentUrl = publication.links.first(where: { $0.type == "application/vnd.opds.authentication.v1.0+json" })?.href
    
    let logoString = publication.images?.first(where: { $0.rel == "http://opds-spec.org/image/thumbnail" })?.href
    if let modString = logoString?.replacingOccurrences(of: "data:image/png;base64,", with: ""),
      let logoData = Data.init(base64Encoded: modString),
      let logoImage = UIImage(data: logoData) {
      logo = logoImage
    } else {
      logo = UIImage.init(named: "LibraryLogoMagic")!
    }
  }


  /// Load authentication documents from the network or cache.
  /// Providing the signedInStateProvider might lead to presentation of announcements
  /// - Parameter signedInStateProvider: The object providing user signed in state for presenting announcement. nil means no announcements will be present
  /// - Parameter completion: Always invoked at the end of the load process.
  /// No guarantees are being made about whether this is called on the main
  /// thread or not. This closure is not retained by `self`.
  @objc(loadAuthenticationDocumentUsingSignedInStateProvider:completion:)
  func loadAuthenticationDocument(using signedInStateProvider: NYPLSignedInStateProvider? = nil, completion: @escaping (Bool) -> ()) {
    Log.debug(#function, "Entering...")
    guard let urlString = authenticationDocumentUrl, let url = URL(string: urlString) else {
      NYPLErrorLogger.logError(
        withCode: .noURL,
        summary: "Authentication Document Load Error",
        message: "Failed to load authentication document because its URL is invalid",
        metadata: ["self.uuid": uuid]
      )
      completion(false)
      return
    }

    Log.info(#function, "GETting auth doc at \(url)")
    NYPLNetworkExecutor.shared.GET(url) { result in
      switch result {
      case .success(let serverData, _):
        do {
          self.authenticationDocument = try
            OPDS2AuthenticationDocument.fromData(serverData)
          if let provider = signedInStateProvider,
            provider.isSignedIn(),
            let announcements = self.authenticationDocument?.announcements {
            DispatchQueue.main.async {
              NYPLAnnouncementBusinessLogic.shared.presentAnnouncements(announcements)
            }
          }
          completion(true)
        } catch (let error) {
          let responseBody = String(data: serverData, encoding: .utf8)
          NYPLErrorLogger.logError(
            withCode: .authDocParseFail,
            summary: "Authentication Document Load Error",
            message: "Failed to parse authentication document data obtained from \(url)",
            metadata: [
              "underlyingError": error,
              "responseBody": responseBody ?? ""
            ]
          )
          completion(false)
        }
      case .failure(let error, _):
        NYPLErrorLogger.logError(
          withCode: .authDocLoadFail,
          summary: "Authentication Document Load Error",
          message: "Request to load authentication document at \(url) failed.",
          metadata: ["underlyingError": error]
        )
        completion(false)
      }
    }
  }
}

extension AccountDetails {
  override var debugDescription: String {
    return """
    supportsSimplyESync=\(supportsSimplyESync)
    supportsCardCreator=\(supportsCardCreator)
    supportsReservations=\(supportsReservations)
    """
  }
}

extension Account {
  override var debugDescription: String {
    return """
    name=\(name)
    uuid=\(uuid)
    catalogURL=\(String(describing: catalogUrl))
    authDocURL=\(String(describing: authenticationDocumentUrl))
    details=\(String(describing: details?.debugDescription))
    """
  }
}

// MARK: URLType
@objc enum URLType: Int {
  case acknowledgements
  case contentLicenses
  case eula
  case privacyPolicy
  case annotations
}

// MARK: LoginKeyboard
@objc enum LoginKeyboard: Int, Codable {
  case standard
  case email
  case numeric
  case none

  init?(_ stringValue: String?) {
    if stringValue == "Default" {
      self = .standard
    } else if stringValue == "Email address" {
      self = .email
    } else if stringValue == "Number pad" {
      self = .numeric
    } else if stringValue == "No input" {
      self = .none
    } else {
      Log.error(#file, "Invalid init parameter for PatronPINKeyboard: \(stringValue ?? "nil")")
      return nil
    }
  }
}
