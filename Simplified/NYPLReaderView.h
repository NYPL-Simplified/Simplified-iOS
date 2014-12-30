typedef NS_ENUM(NSInteger, NYPLReaderViewGesture) {
  NYPLReaderViewGestureToggleUserInterface
};

@protocol NYPLReaderView

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;

@end

@protocol NYPLReaderViewDelegate

- (void)readerView:(id<NYPLReaderView>)readerView didEncounterCorruptionForBook:(NYPLBook *)book;
- (void)readerView:(id<NYPLReaderView>)readerView didReceiveGesture:(NYPLReaderViewGesture)gesture;
- (void)readerViewDidFinishLoading:(id<NYPLReaderView>)readerView;

@end