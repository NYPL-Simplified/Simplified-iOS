@class NYPLBook;
@class NYPLBookDownloadFailedCell;

@protocol NYPLBookDownloadFailedCellDelegate

- (void)didSelectCancelForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell;
- (void)didSelectTryAgainForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell;

@end

@interface NYPLBookDownloadFailedCell : UICollectionViewCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDownloadFailedCellDelegate> delegate;

@end
