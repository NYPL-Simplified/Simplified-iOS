typedef NS_ENUM(NSInteger, NYPLBookContentType) {
  NYPLBookContentTypeEPUB,
  NYPLBookContentTypeAudiobook,
  NYPLBookContentTypePDF,
  NYPLBookContentTypeUnsupported
};

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *string);
