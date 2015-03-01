typedef NS_ENUM(NSInteger, NYPLBookState) {
  NYPLBookStateUnregistered,
  NYPLBookStateDownloadNeeded,
  NYPLBookStateDownloading,
  NYPLBookStateDownloadFailed,
  NYPLBookStateDownloadSuccessful,
  NYPLBookStateUsed
};

NYPLBookState NYPLBookStateFromString(NSString *string);

NSString *NYPLBookStateToString(NYPLBookState state);