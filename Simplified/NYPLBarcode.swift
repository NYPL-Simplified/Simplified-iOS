import Foundation
import ZXingObjC

fileprivate let barcodeHeight: CGFloat = 100
fileprivate let maxBarcodeWidth: CGFloat = 414

@objc enum NYPLBarcodeType: Int {
  case codabar
  case code39
  case qrCode
  case code128
}

fileprivate func ZXBarcodeFormatFor(_ NYPLBarcodeType:NYPLBarcodeType) -> ZXBarcodeFormat {
  switch NYPLBarcodeType {
  case .codabar:
    return kBarcodeFormatCodabar
  case .code39:
    return kBarcodeFormatCode39
  case .qrCode:
    return kBarcodeFormatQRCode
  case .code128:
    return kBarcodeFormatCode128
  }
}

/// Manage creation and scanning of barcodes on library cards.
/// Keep any third party dependency abstracted out of the main app.
final class NYPLBarcode: NSObject {

  var libraryName: String?

  init (library: String) {
    self.libraryName = library
  }

  func image(fromString stringToEncode: String, superviewWidth: CGFloat, type: NYPLBarcodeType) -> UIImage?
  {
    let barcodeWidth = imageWidthFor(superviewWidth)
    let encodeHints = ZXEncodeHints.init()
    encodeHints.margin = 0
    if let image = NYPLZXingEncoder.encode(with: stringToEncode,
                                           format: ZXBarcodeFormatFor(type),
                                           width: Int32(barcodeWidth),
                                           height: Int32(barcodeHeight),
                                           library: self.libraryName ?? "Unknown",
                                           encodeHints: encodeHints)
    {
      return image
    } else {
      Log.error(#file, "Failed to create barcode image.")
      return nil
    }
  }

  class func presentScanner(withCompletion completion: @escaping (String?) -> ())
  {
    guard let scannerVC = NYPLBarcodeScanningViewController.init(completion: completion) else { return }
    let navController = UINavigationController.init(rootViewController: scannerVC)
    NYPLRootTabBarController.shared().safelyPresentViewController(navController, animated: true, completion: nil)
  }

  private func imageWidthFor(_ superviewWidth: CGFloat) -> CGFloat
  {
    if superviewWidth > maxBarcodeWidth {
      return maxBarcodeWidth
    } else {
      return superviewWidth
    }
  }
}
