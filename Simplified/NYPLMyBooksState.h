typedef NS_ENUM(NSInteger, NYPLMyBooksState) {
  NYPLMyBooksStateDownloading,
  NYPLMyBooksStateUnregistered
};

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *string);

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state);