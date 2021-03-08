#import "NYPLBookContentType.h"
#import "NYPLBookAcquisitionPath.h"

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *const string)
{
  if ([[NYPLBookAcquisitionPath audiobookTypes] containsObject:string]) {
    return NYPLBookContentTypeAudiobook;
  } else if ([string isEqualToString:ContentTypeEpubZip]) {
    return NYPLBookContentTypeEPUB;
  } else if ([string isEqualToString:ContentTypeOpenAccessPDF]) {
    return NYPLBookContentTypePDF;
  }
  return NYPLBookContentTypeUnsupported;
}
