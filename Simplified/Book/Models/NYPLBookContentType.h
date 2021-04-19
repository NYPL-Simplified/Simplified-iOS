typedef NS_ENUM(NSInteger, NYPLBookContentType) {
  NYPLBookContentTypeEPUB,
  NYPLBookContentTypeAudiobook,
  NYPLBookContentTypePDF,
  NYPLBookContentTypeAxis,
  NYPLBookContentTypeUnsupported
};

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *string);
