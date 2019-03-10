import Foundation
import PDFRendererProvider

@objc final class NYPLPDFViewControllerDelegate: NSObject, MinitexPDFViewControllerDelegate {

  let bookIdentifier: String

  @objc init(bookIdentifier: String) {
    self.bookIdentifier = bookIdentifier
  }

  func userDidNavigate(toPage page: MinitexPDFPage) {

    Log.debug(#file, "NYPLPDFViewControllerDelegate: User did navigate to page: \(page)")

    let data = page.toData()
    if let string = String(data: data, encoding: .utf8),
      let bookLocation = NYPLBookLocation(locationString: string, renderer: "PDFRendererProvider") {
      NYPLBookRegistry.shared().setLocation(bookLocation, forIdentifier: self.bookIdentifier)
    } else {
      Log.error(#file, "Error creating and saving PDF Page Location")
    }
  }

  func userDidCreate(bookmark: MinitexPDFPage) {

    //WIP
    /**
    Log.debug(#file, "NYPLPDFViewControllerDelegate: User did navigate to page: \(bookmark)")

    let data = bookmark.toData()
    if let string = String(data: data, encoding: .utf8),
      let bookLocation = NYPLBookLocation(locationString: string, renderer: "PDFRendererProvider") {
//      NYPLBookRegistry.shared().add(bookLocation, forIdentifier: self.bookIdentifier)
    } else {
      Log.error(#file, "Error creating and saving PDF Page Location")
    }
     */
  }

  func userDidDelete(bookmark: MinitexPDFPage) {
    //TODO save to book registry
  }

  func userDidCreate(annotation: MinitexPDFAnnotation) { }
  func userDidDelete(annotation: MinitexPDFAnnotation) { }
}
