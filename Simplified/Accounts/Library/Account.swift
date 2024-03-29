import UIKit

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

@objc protocol NYPLReaderServerPermissions {
  var syncPermissionGranted:Bool {get}
}

// MARK: AccountDetails
// Extra data that gets loaded from an OPDS2AuthenticationDocument,
@objcMembers final class AccountDetails: NSObject, NYPLReaderServerPermissions {
  enum AuthType: String, Codable {
    /// This is used with barcode/username credentials on SimplyE. It was also
    /// used for FirstBook authentication on Open eBooks versions before 2.4.0.
    case basic = "http://opds-spec.org/auth/basic"
    /// This is used for the "Book for All" collection in SimplyE.
    case coppa = "http://librarysimplified.org/terms/authentication/gate/coppa"
    /// This is used by Clever on Open eBooks.
    case oauthIntermediary = "http://librarysimplified.org/authtype/OAuth-with-intermediary"
    /// This is used by FirstBook on Open eBooks. This is using the
    /// OAuth 2.0 Password Grant flow.
    case oauthClientCredentials = "http://librarysimplified.org/authtype/OAuth-Client-Credentials"
    case saml = "http://librarysimplified.org/authtype/SAML-2.0"
    case anonymous = "http://librarysimplified.org/rel/auth/anonymous"
    case none

    var requiresUserAuthentication: Bool {
      switch self {
      case .basic, .oauthIntermediary, .oauthClientCredentials, .saml:
        return true
      case .coppa, .anonymous, .none:
        return false
      }
    }
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

      case .oauthIntermediary, .oauthClientCredentials:
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

    var requiresUserAuthentication: Bool {
      return authType.requiresUserAuthentication
    }

    var needsAgeCheck: Bool {
      return authType == .coppa
    }

    func coppaURL(isOfAge: Bool) -> URL? {
      isOfAge ? coppaOverUrl : coppaUnderUrl
    }

    var isBasic: Bool {
      return authType == .basic
    }

    var isOauthIntermediary: Bool {
      return authType == .oauthIntermediary
    }

    var isOauthClientCredentials: Bool {
      return authType == .oauthClientCredentials
    }

    var isOauth: Bool {
      return isOauthIntermediary || isOauthClientCredentials
    }

    var isSaml: Bool {
      return authType == .saml
    }

    var catalogRequiresAuthentication: Bool {
      // you need a token in order to access catalogs for oauth types or SAML
      return authType == .oauthIntermediary || authType == .oauthClientCredentials || authType == .saml
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

    override var description: String {
      return "\(authType)"
    }
  }

  let defaults:UserDefaults
  let uuid:String
  let supportsSimplyESync:Bool
  let supportsCardCreator:Bool
  let supportsReservations:Bool
  var supportsUnsubscribeEmail: Bool {
    urlUnsubscribeEmail != nil
  }
  let auths: [Authentication]

  let mainColor:String?
  let userProfileUrl:String?
  let signUpUrl:URL?
  let loansUrl:URL?
  var defaultAuth: Authentication? {
    guard auths.count > 1 else { return auths.first }
    return auths.first(where: { !$0.catalogRequiresAuthentication }) ?? auths.first
  }
  var needsAgeCheck: Bool {
    // this will tell if any authentication method requires age check
    return auths.contains(where: { $0.needsAgeCheck })
  }

  fileprivate var urlAnnotations:URL?
  fileprivate var urlAcknowledgements:URL?
  fileprivate var urlContentLicenses:URL?
  fileprivate var urlEULA:URL?
  fileprivate var urlPrivacyPolicy:URL?
  fileprivate var urlUnsubscribeEmail:URL?
  
  var eulaIsAccepted:Bool {
    get {
      return getAccountDictionaryKey(NYPLSettings.userHasAcceptedEULAKey) as? Bool ?? false

    }
    set {
      setAccountDictionaryKey(NYPLSettings.userHasAcceptedEULAKey,
                              toValue: newValue as AnyObject)
    }
  }
  var syncPermissionGranted:Bool {
    get {
      return getAccountDictionaryKey(accountSyncEnabledKey) as? Bool ?? false
    }
    set {
      setAccountDictionaryKey(accountSyncEnabledKey, toValue: newValue as AnyObject)
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      return getAccountDictionaryKey(userAboveAgeKey) as? Bool ?? false

    }
    set {
      setAccountDictionaryKey(userAboveAgeKey, toValue: newValue as AnyObject)
    }
  }
  
  init(authenticationDocument: OPDS2AuthenticationDocument, uuid: String) {
    defaults = .standard
    self.uuid = uuid

    let auths = authenticationDocument.authentication?.map({ (opdsAuth) -> Authentication in
      return Authentication.init(auth: opdsAuth)
    }) ?? []

    // for OpenE, if OAuthClientCredentials auth type is allowed, that replaces
    // Basic authentication
#if OPENEBOOKS
    if auths.contains(where: { auth in
      auth.authType == .oauthClientCredentials
    }) {
      self.auths = auths.filter { auth in
        !auth.isBasic
      }
    } else {
      self.auths = auths
    }
#else
    self.auths = auths
#endif

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
    
    urlUnsubscribeEmail = URL.init(string: authenticationDocument.links?.first(where: { $0.rel == "http://librarysimplified.org/rel/email/unsubscribe/options" })?.href ?? "")
    
    super.init()
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "privacy-policy" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forURLType: .privacyPolicy)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "terms-of-service" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forURLType: .eula)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "license" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forURLType: .contentLicenses)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "copyright" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forURLType: .acknowledgements)
    }
    
    if let url = urlUnsubscribeEmail {
      setURL(url, forURLType: .unsubscribeEmail)
    }
  }

  func setURL(_ URL: URL, forURLType urlType: URLType) -> Void {
    switch urlType {
    case .acknowledgements:
      urlAcknowledgements = URL
    case .contentLicenses:
      urlContentLicenses = URL
    case .eula:
      urlEULA = URL
    case .privacyPolicy:
      urlPrivacyPolicy = URL
    case .annotations:
      urlAnnotations = URL
    case .unsubscribeEmail:
      urlUnsubscribeEmail = URL
    }

    setAccountDictionaryKey(urlType.stringValue, toValue: URL.absoluteString as AnyObject)
  }
  
  func getLicenseURL(_ type: URLType) -> URL? {
    let url: URL?
    switch type {
    case .acknowledgements:
      url = urlAcknowledgements
    case .contentLicenses:
      url = urlContentLicenses
    case .eula:
      url = urlEULA
    case .privacyPolicy:
      url = urlPrivacyPolicy
    case .annotations:
      url = urlAnnotations
    case .unsubscribeEmail:
      url = urlUnsubscribeEmail
    }

    if url != nil {
      return url
    }

    if let urlString = getAccountDictionaryKey(type.stringValue) as? String {
      return URL(string: urlString)
    }

    return nil
  }
  
  private func setAccountDictionaryKey(_ key: String, toValue value: AnyObject) {
    if var savedDict = defaults.value(forKey: self.uuid) as? [String: AnyObject] {
      savedDict[key] = value
      defaults.set(savedDict, forKey: self.uuid)
    } else {
      defaults.set([key:value], forKey: self.uuid)
    }
  }
  
  private func getAccountDictionaryKey(_ key: String) -> AnyObject? {
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
  /// - Parameter completion: Always invoked at the end of the load process but before showing the announcements UI (when needed).
  /// No guarantees are being made about whether this is called on the main
  /// thread or not. This closure is not retained by `self`.
  @objc(loadAuthenticationDocumentUsingSignedInStateProvider:completion:)
  func loadAuthenticationDocument(using signedInStateProvider: NYPLSignedInStateProvider? = nil, completion: @escaping (Bool, Error?) -> ()) {
    Log.debug(#function, "Entering...")
    guard let urlString = authenticationDocumentUrl, let url = URL(string: urlString) else {
      NYPLErrorLogger.logError(
        withCode: .noURL,
        summary: "Failed to load authentication document because its URL is invalid",
        metadata: ["self.uuid": uuid,
                   "urlString": authenticationDocumentUrl ?? "N/A"]
      )
      completion(false, nil)
      return
    }

    NYPLNetworkExecutor.shared.GET(url) { result in
      switch result {
      case .success(let serverData, _):
        do {
          self.authenticationDocument = try
            OPDS2AuthenticationDocument.fromData(serverData)
          completion(true, nil)
          if let provider = signedInStateProvider,
            provider.isSignedIn(),
            let announcements = self.authenticationDocument?.announcements {
            DispatchQueue.main.async {
              NYPLAnnouncementBusinessLogic.shared.presentAnnouncements(announcements)
            }
          }
        } catch (let error) {
          let responseBody = String(data: serverData, encoding: .utf8)
          NYPLErrorLogger.logError(
            withCode: .authDocParseFail,
            summary: "Authentication Document Data Parse Error",
            metadata: [
              "underlyingError": error,
              "responseBody": responseBody ?? "N/A",
              "url": url
            ]
          )
          completion(false, error)
        }
      case .failure(let error, _):
        NYPLErrorLogger.logError(
          withCode: .authDocLoadFail,
          summary: "Authentication Document request failed to load",
          metadata: [
            "loadError": error,
            "url": url,
            "HTTPStatusCode": error.httpStatusCode
          ]
        )

        completion(false, error)
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
    supportsUnsubscribeEmail=\(supportsUnsubscribeEmail)
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
  case unsubscribeEmail

  var stringValue: String {
    switch self {
    case .acknowledgements:
      return "urlAcknowledgements"
    case .contentLicenses:
      return "urlContentLicenses"
    case .eula:
      return "urlEULA"
    case .privacyPolicy:
      return "urlPrivacyPolicy"
    case .annotations:
      return "urlAnnotations"
    case .unsubscribeEmail:
      return "urlUnsubscribeEmail"
    }
  }
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
