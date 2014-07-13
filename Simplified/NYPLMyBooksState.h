typedef NS_ENUM(NSInteger, NYPLMyBooksState) {
  NYPLMyBooksStateDownloading
};

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *string);

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state);