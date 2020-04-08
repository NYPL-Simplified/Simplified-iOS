#import "NYPLBookContentType.h"
#import "NYPLBookAcquisitionPath.h"

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *const string)
{
  if ([string isEqualToString:ContentTypeFindaway] ||
      [string isEqualToString:ContentTypeOpenAccessAudiobook] ||
      [string isEqualToString:ContentTypeFeedbooksAudiobook]) {
    return NYPLBookContentTypeAudiobook;
  } else if ([string isEqualToString:ContentTypeEpubZip]) {
    return NYPLBookContentTypeEPUB;
  } else if ([string isEqualToString:ContentTypeOpenAccessPDF]) {
    return NYPLBookContentTypePDF;
  } else {
    return NYPLBookContentTypeUnsupported;
  }
}
