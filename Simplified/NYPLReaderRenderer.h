@class NYPLBook;

// No such actual class exists. This merely to provides a little safety around reader-specific
// TOC-related location information. Any object that wants to do something with an opaque location
// must verify that it is of the correct class and then cast it appropriately.
@class NYPLReaderRendererOpaqueLocation;

typedef NS_ENUM(NSInteger, NYPLReaderRendererGesture) {
  NYPLReaderRendererGestureToggleUserInterface
};

@protocol NYPLReaderRenderer

@property (nonatomic, readonly) BOOL bookIsCorrupt;
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, readonly) NSArray *TOCElements;

// This must be called with a reader-appropriate underlying value. Readers implementing this should
// throw |NSInvalidArgumentException| in the event it is not.
- (void)openOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation;

@end

@protocol NYPLReaderRendererDelegate

- (void)renderer:(id<NYPLReaderRenderer>)renderer
didEncounterCorruptionForBook:(NYPLBook *)book;

- (void)renderer:(id<NYPLReaderRenderer>)renderer
didReceiveGesture:(NYPLReaderRendererGesture)gesture;

- (void)rendererDidRegisterGesture:(id<NYPLReaderRenderer>)renderer;

- (void)rendererDidFinishLoading:(id<NYPLReaderRenderer>)renderer;

-(void) didUpdateProgressSpineItemPercentage: (NSNumber *)spineItemPercentage bookPercentage: (NSNumber *) bookPercentage withCurrentSpineItemDetails: (NSDictionary *) currentSpineItemDetails;
@end