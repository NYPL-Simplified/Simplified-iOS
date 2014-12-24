typedef NS_ENUM(NSInteger, NYPLReaderViewGesture) {
  NYPLReaderViewGestureLeft,
  NYPLReaderViewGestureCenter,
  NYPLReaderViewGestureRight
};

@protocol NYPLReaderView

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;

@end