import Foundation

/**
  Represents a Problem Document, outlined in https://tools.ietf.org/html/rfc7807
 */
@objcMembers class NYPLProblemDocument: NSObject, Codable {
  static let TypeNoActiveLoan =
    "http://librarysimplified.org/terms/problem/no-active-loan";
  static let TypeLoanAlreadyExists =
    "http://librarysimplified.org/terms/problem/loan-already-exists";
  static let TypeInvalidCredentials =
    "http://librarysimplified.org/terms/problem/credentials-invalid";

  let type: String?
  let title: String?
  let status: Int?
  let detail: String?
  let instance: String?
  
  fileprivate init(_ dict: [String : Any]) {
    self.type = dict["type"] as? String
    self.title = dict["title"] as? String
    self.status = dict["status"] as? Int
    self.detail = dict["detail"] as? String
    self.instance = dict["instance"] as? String
    super.init()
  }
  
  /**
    Factory method that creates a ProblemDocument from data
    @param data data with which to populate the ProblemDocument
    @return a ProblemDocument built from the given data
   */
  @objc static func fromData(_ data: Data) throws -> NYPLProblemDocument {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return try jsonDecoder.decode(NYPLProblemDocument.self, from: data)
  }
  
  /**
    Factory method that creates a ProblemDocument from a dictionary
    @param dict data with which to populate the ProblemDocument
    @return a ProblemDocument built from the given dicationary
   */
  @objc static func fromDictionary(_ dict: [String : Any]) -> NYPLProblemDocument {
    return NYPLProblemDocument(dict)
  }
}
