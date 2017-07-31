import Foundation

final class NYPLBookAuthor: NSObject {

  let name: String
  let relatedBooksLink: URL?

  init(authorName: String, relatedBooksLink: URL?) {
    self.name = authorName
    self.relatedBooksLink = relatedBooksLink
  }
}
