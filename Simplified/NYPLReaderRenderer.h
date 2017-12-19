@class NYPLBook;

// No such actual class exists. This merely to provides a little safety around reader-specific
// TOC-related location information. Any object that wants to do something with an opaque location
// must verify that it is of the correct class and then cast it appropriately.
@class NYPLReaderRendererOpaqueLocation;
@class NYPLReaderBookmark;

typedef NS_ENUM(NSInteger, NYPLReaderRendererGesture) {
  NYPLReaderRendererGestureToggleUserInterface
};

@protocol NYPLReaderRenderer

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, readonly, nonnull) NSArray *TOCElements;
@property (nonatomic, readonly, nonnull) NSArray<NYPLReaderBookmark *> *bookmarkElements;

// This must be called with a reader-appropriate underlying value. Readers implementing this should
// throw |NSInvalidArgumentException| in the event it is not.
- (void)openOpaqueLocation:(nonnull NYPLReaderRendererOpaqueLocation *)opaqueLocation;

- (void)gotoBookmark:(nonnull NYPLReaderBookmark *)bookmark;

@end

@protocol NYPLReaderRendererDelegate

- (void)renderer:(nonnull id<NYPLReaderRenderer>)renderer
didEncounterCorruptionForBook:(nonnull NYPLBook *)book;

- (void)rendererDidFinishLoading:(nonnull id<NYPLReaderRenderer>)renderer;

- (void)renderer:(nonnull id<NYPLReaderRenderer>)renderer
didUpdateProgressWithinBook:(float)progressWithinBook
       pageIndex:(NSUInteger)pageIndex
       pageCount:(NSUInteger)pageCount
  spineItemTitle:(nullable NSString *)spineItemTitle;

- (void)rendererDidBeginLongLoad:(nonnull id<NYPLReaderRenderer>)render;

- (void)renderDidEndLongLoad:(nonnull id<NYPLReaderRenderer>)render;

- (void)updateBookmarkIcon:(BOOL)on;
- (void)updateCurrentBookmark:(nullable NYPLReaderBookmark*)bookmark;

- (void)renderer:(nonnull id<NYPLReaderRenderer>)render didReceiveGesture:(NYPLReaderRendererGesture)gesture;

@end
