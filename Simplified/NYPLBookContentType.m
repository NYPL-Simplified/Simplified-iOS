#import "NYPLBookContentType.h"
#import "NYPLBookAcquisitionPath.h"

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *const string)
{
  if ([string isEqualToString:ContentTypeFindaway] ||
      [string isEqualToString:ContentTypeOpenAccessAudiobook]) {
    return NYPLBookContentTypeAudiobook;
  } else if ([string isEqualToString:ContentTypeEpubZip] ||
             [string isEqualToString:ContentTypeAdobeAdept]) {
    return NYPLBookContentTypeEPUB;
  } else {
    return NYPLBookContentTypeUnsupported;
  }
}
