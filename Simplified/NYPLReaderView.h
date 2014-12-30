typedef NS_ENUM(NSInteger, NYPLReaderViewGesture) {
  NYPLReaderViewGestureToggleUserInterface
};

@protocol NYPLReaderView

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;

@end