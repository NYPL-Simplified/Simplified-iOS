import Foundation
import ZXingObjC

fileprivate let barcodeHeight: CGFloat = 100
fileprivate let maxBarcodeWidth: CGFloat = 500

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

  class func image(fromString string: String, superviewWidth: CGFloat, type: NYPLBarcodeType) -> UIImage?
  {
    let width = imageWidthFor(superviewWidth)
    guard let writer = ZXMultiFormatWriter.writer() as? ZXWriter else { return nilWithGenericError() }
    do {
      let result = try writer.encode(string,
                                     format: ZXBarcodeFormatFor(type),
                                     width: Int32(width),
                                     height: Int32(barcodeHeight))
      if let cgImage = ZXImage.init(matrix: result).cgimage {
        return UIImage.init(cgImage: cgImage)
      } else {
        return nilWithGenericError()
      }
    } catch {
      Log.error(#file, "Failed to create barcode image: \(error.localizedDescription)")
      return nil
    }
  }

  class func presentScanner(withCompletion completion: @escaping (String?) -> ())
  {
    guard let scannerVC = NYPLBarcodeScanningViewController.init(completion: completion) else { return }
    let navController = UINavigationController.init(rootViewController: scannerVC)
    NYPLRootTabBarController.shared().safelyPresentViewController(navController, animated: true, completion: nil)
  }

  private class func imageWidthFor(_ superviewWidth: CGFloat) -> CGFloat
  {
    if superviewWidth > maxBarcodeWidth {
      return maxBarcodeWidth
    } else {
      return superviewWidth
    }
  }

  private class func nilWithGenericError() -> UIImage?
  {
    Log.error(#file, "Error creating image from barcode string.")
    return nil
  }
}
