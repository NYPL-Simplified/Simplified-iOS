import Foundation
import PDFRendererProvider

@objc final class NYPLPDFViewControllerDelegate: NSObject, MinitexPDFViewControllerDelegate {

  let bookIdentifier: String

  @objc init(bookIdentifier: String) {
    self.bookIdentifier = bookIdentifier
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.Used.rawValue, forIdentifier: bookIdentifier)
  }

  func userDidNavigate(toPage page: MinitexPDFPage) {

    Log.debug(#file, "User did navigate to page: \(page)")

    let data = page.toData()
    if let string = String(data: data, encoding: .utf8),
      let bookLocation = NYPLBookLocation(locationString: string, renderer: "PDFRendererProvider") {
      NYPLBookRegistry.shared().setLocation(bookLocation, forIdentifier: self.bookIdentifier)
    } else {
      Log.error(#file, "Error creating and saving PDF Page Location")
    }
  }

  func userDidCreate(bookmark: MinitexPDFPage) {

    Log.debug(#file, "User did add bookmark: \(bookmark)")

    let data = bookmark.toData()
    if let string = String(data: data, encoding: .utf8),
      let bookLocation = NYPLBookLocation(locationString: string, renderer: "PDFRendererProvider") {
      NYPLBookRegistry.shared().addGenericBookmark(bookLocation, forIdentifier: self.bookIdentifier)
    } else {
      Log.error(#file, "Error adding PDF Page Location")
    }
  }

  func userDidDelete(bookmark: MinitexPDFPage) {

    Log.debug(#file, "User did delete bookmark: \(bookmark)")

    let data = bookmark.toData()
    if let string = String(data: data, encoding: .utf8),
      let bookLocation = NYPLBookLocation(locationString: string, renderer: "PDFRendererProvider") {
      NYPLBookRegistry.shared().deleteGenericBookmark(bookLocation, forIdentifier: self.bookIdentifier)
    } else {
      Log.error(#file, "Error deleting PDF Page Location")
    }
  }

  func userDidCreate(annotation: MinitexPDFAnnotation) { }
  func userDidDelete(annotation: MinitexPDFAnnotation) { }
}
