typedef NS_ENUM(NSInteger, NYPLMyBooksState) {
  NYPLMyBooksStateUnregistered,
  NYPLMyBooksStateDownloading,
  NYPLMyBooksStateDownloadFailed,
  NYPLMyBooksStateDownloadSuccessful
};

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *string);

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state);