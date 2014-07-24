typedef NS_ENUM(NSInteger, NYPLMyBooksState) {
  NYPLMyBooksStateUnregistered,
  NYPLMyBooksStateDownloadNeeded,
  NYPLMyBooksStateDownloading,
  NYPLMyBooksStateDownloadFailed,
  NYPLMyBooksStateDownloadSuccessful
};

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *string);

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state);