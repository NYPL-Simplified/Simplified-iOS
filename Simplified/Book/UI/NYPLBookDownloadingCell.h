#import "NYPLBookCell.h"

@class NYPLBook;
@class NYPLBookDownloadingCell;

@protocol NYPLBookDownloadingCellDelegate

- (void)didSelectCancelForBookDownloadingCell:(NYPLBookDownloadingCell *)cell;
- (void)didSelectListenForBookDownloadingCell:(NYPLBookDownloadingCell *)cell;

@end

@interface NYPLBookDownloadingCell : NYPLBookCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDownloadingCellDelegate> delegate;
@property (nonatomic) double downloadProgress;
#if FEATURE_AUDIOBOOKS
- (void)enableListenButton;
#endif

@end
