#import "NYPLBookContentType.h"
#import "NYPLOPDSAcquisitionPath.h"

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *const string)
{
  if ([[NYPLOPDSAcquisitionPath audiobookTypes] containsObject:string]) {
    return NYPLBookContentTypeAudiobook;
  } else if ([string isEqualToString:ContentTypeEpubZip]
    || [string isEqualToString:ContentTypeAxis360]) {
    return NYPLBookContentTypeEPUB;
  } else if ([string isEqualToString:ContentTypeOpenAccessPDF]) {
    return NYPLBookContentTypePDF;
  }
  return NYPLBookContentTypeUnsupported;
}
