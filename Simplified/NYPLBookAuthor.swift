import Foundation

@objc final class NYPLBookAuthor: NSObject {

  var name: String
  var relatedBooksLink: URL?

  init(authorName: String) {
    name = authorName
  }
}

