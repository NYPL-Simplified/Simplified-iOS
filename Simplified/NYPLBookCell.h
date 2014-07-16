#import "NYPLBook.h"
#import "NYPLMyBooksState.h"

CGSize NYPLBookCellSizeForIdiomAndOrientation(UIUserInterfaceIdiom idiom,
                                              UIInterfaceOrientation orientation);

@class NYPLBookCell;

@protocol NYPLBookCellDelegate

- (void)didSelectDownloadForBookCell:(NYPLBookCell *)cell;

@end

@interface NYPLBookCell : UICollectionViewCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookCellDelegate> delegate;
@property (nonatomic) double downloadProgress;
@property (nonatomic) NYPLMyBooksState state;

@end
