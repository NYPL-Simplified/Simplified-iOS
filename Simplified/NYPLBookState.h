typedef NS_ENUM(NSInteger, NYPLBookState) {
  NYPLBookStateUnregistered,
  NYPLBookStateDownloadNeeded,
  NYPLBookStateDownloading,
  NYPLBookStateDownloadFailed,
  NYPLBookStateDownloadSuccessful,
  NYPLBookStateHolding,
  NYPLBookStateUsed
};

NYPLBookState NYPLBookStateFromString(NSString *string);

NSString *NYPLBookStateToString(NYPLBookState state);