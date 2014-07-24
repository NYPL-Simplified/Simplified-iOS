@class NYPLBook;
@class NYPLBookDownloadingCell;

@protocol NYPLBookDownloadingCellDelegate

- (void)didSelectCancelForBookDownloadingCell:(NYPLBookDownloadingCell *)cell;

@end

@interface NYPLBookDownloadingCell : UICollectionViewCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic) double downloadProgress;

@end
