import Foundation
import ZXingObjC

fileprivate let barcodeHeight: CGFloat = 100

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

  class func image(fromString string: String, size: CGSize, type: NYPLBarcodeType) -> UIImage?
  {
    let writer = ZXMultiFormatWriter.writer() as? ZXWriter
    do {
      let result = try writer?.encode(string, format: ZXBarcodeFormatFor(type), width: Int32(size.width), height: Int32(size.height))

      if let cgImage = ZXImage.init(matrix: result).cgimage {
        return UIImage.init(cgImage: cgImage)
      } else {
        Log.error(#file, "Error creating image from barcode string.")
        return nil
      }
    } catch {
      Log.error(#file, "Failed to create barcode image with error: \(error.localizedDescription)")
      return nil
    }
  }

  class func imageSize(forSuperviewBounds bounds: CGRect) -> CGSize
  {
    if bounds.size.width > 500 {
      return CGSize(width: 500, height: barcodeHeight)
    } else {
      return CGSize(width: bounds.size.width, height: barcodeHeight)
    }
  }

  class func presentScanner(withCompletion completion: @escaping (String?) -> ())
  {
    guard let scannerVC = NYPLBarcodeScanningViewController.init(completion: completion) else { return }
    let navController = UINavigationController.init(rootViewController: scannerVC)
    NYPLRootTabBarController.shared().safelyPresentViewController(navController, animated: true, completion: nil)
  }
}
