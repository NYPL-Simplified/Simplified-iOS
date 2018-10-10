typedef NS_ENUM(NSInteger, NYPLBookContentType) {
  NYPLBookContentTypeEPUB,
  NYPLBookContentTypeAudiobook,
  NYPLBookContentTypeUnsupported
};

NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *string);
