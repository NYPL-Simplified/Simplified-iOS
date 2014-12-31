@class NYPLReaderOpaqueLocation;

typedef NS_ENUM(NSInteger, NYPLReaderViewGesture) {
  NYPLReaderViewGestureToggleUserInterface
};

@protocol NYPLReaderView

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, readonly) NSArray *TOCElements;

// This must be called with a reader-appropriate underlying value. Readers implementing this should
// throw |NSInvalidArgumentException| in the event it is not.
- (void)openOpaqueLocation:(NYPLReaderOpaqueLocation *)opaqueLocation;

@end

@protocol NYPLReaderViewDelegate

- (void)readerView:(id<NYPLReaderView>)readerView didEncounterCorruptionForBook:(NYPLBook *)book;
- (void)readerView:(id<NYPLReaderView>)readerView didReceiveGesture:(NYPLReaderViewGesture)gesture;
- (void)readerViewDidFinishLoading:(id<NYPLReaderView>)readerView;

@end