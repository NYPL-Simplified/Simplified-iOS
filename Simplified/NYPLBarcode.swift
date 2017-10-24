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

/// Manage creation of barcode images that are scannable by physical scanners.
/// Keep any third party dependency abstracted out of the main app.
final class NYPLBarcode: NSObject {

  class func image(string: String, size: CGSize, type: NYPLBarcodeType) -> UIImage?
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

  class func size(forSuperviewBounds bounds: CGRect) -> CGSize
  {
    if bounds.size.width > 500 {
      return CGSize(width: 500, height: barcodeHeight)
    } else {
      return CGSize(width: bounds.size.width, height: barcodeHeight)
    }
  }
}
