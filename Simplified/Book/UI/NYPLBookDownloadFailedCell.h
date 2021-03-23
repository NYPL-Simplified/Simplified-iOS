#import "NYPLBookCell.h"

@class NYPLBook;
@class NYPLBookDownloadFailedCell;

@protocol NYPLBookDownloadFailedCellDelegate

- (void)didSelectCancelForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell;
- (void)didSelectTryAgainForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell;

@end

@interface NYPLBookDownloadFailedCell : NYPLBookCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDownloadFailedCellDelegate> delegate;

@end
