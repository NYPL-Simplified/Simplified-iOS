#if FEATURE_AUDIOBOOKS
@import NYPLAudiobookToolkit;
#endif

#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookButtonsView.h"

/* This class implements a shared delegate that performs all of its duties via the shared registry,
shared cover registry, shared download center, et cetera. */
@interface NYPLBookCellDelegate : NSObject
  <NYPLBookButtonsDelegate, NYPLBookDownloadFailedCellDelegate, NYPLBookDownloadingCellDelegate>

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedDelegate;

@property (nonatomic) NYPLBook *book;
#if FEATURE_AUDIOBOOKS
@property DefaultAudiobookManager *manager;
#endif
@property (strong) NSLock *refreshAudiobookLock;

- (void)presentUnsupportedItemError;

@end
