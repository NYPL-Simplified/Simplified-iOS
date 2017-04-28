#import "NYPLReaderRenderer.h"

@class NYPLBook;

@interface NYPLReaderReadiumView : UIView <NYPLReaderRenderer>

@property (nonatomic, weak) id<NYPLReaderRendererDelegate> delegate;
@property (nonatomic, readonly) BOOL isPageTurning;
@property (nonatomic, readonly) BOOL canGoRight, canGoLeft;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame
                         book:(NYPLBook *)book
                     delegate:(id<NYPLReaderRendererDelegate>)delegate;

- (BOOL) bookHasMediaOverlays;
- (BOOL) bookHasMediaOverlaysBeingPlayed;
- (void) applyMediaOverlayPlaybackToggle;
- (void) openPageLeft;
- (void) openPageRight;
- (BOOL) touchIntersectsLink:(UITouch *)touch;

- (void) syncLastReadingPosition;

- (void) addBookmark;
- (void) deleteBookmark:(NYPLReaderBookmarkElement*)bookmark;

@end
