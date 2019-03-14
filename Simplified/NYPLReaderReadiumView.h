#import "NYPLReaderRenderer.h"

@class NYPLBook;
@class NYPLReadiumViewSyncManager;

@interface NYPLReaderReadiumView : UIView <NYPLReaderRenderer>

@property (nonatomic, weak) id<NYPLReaderRendererDelegate> delegate;
@property (nonatomic) NYPLReadiumViewSyncManager *syncManager;
@property (nonatomic, readonly) BOOL isPageTurning;
@property (nonatomic, readonly) BOOL canGoRight, canGoLeft;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame
                         book:(NYPLBook *)book
                     delegate:(id<NYPLReaderRendererDelegate>)delegate;

- (void) applyMediaOverlayPlaybackToggle;
- (void) openPageLeft;
- (void) openPageRight;

- (NSString*) currentChapter;

- (void) addBookmark;
- (void) deleteBookmark:(NYPLReadiumBookmark*)bookmark;

@end
