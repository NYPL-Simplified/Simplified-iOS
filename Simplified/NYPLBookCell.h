#import "NYPLBook.h"
#import "NYPLMyBooksState.h"

CGSize NYPLBookCellSizeForIdiomAndOrientation(UIUserInterfaceIdiom idiom,
                                              UIInterfaceOrientation orientation);

@class NYPLBookCell;

@protocol NYPLBookCellDelegate

- (void)didSelectDeleteForBookCell:(NYPLBookCell *)cell;
- (void)didSelectDownloadForBookCell:(NYPLBookCell *)cell;
- (void)didSelectReadForBookCell:(NYPLBookCell *)cell;

@end

@interface NYPLBookCell : UICollectionViewCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookCellDelegate> delegate;
@property (nonatomic) BOOL downloadButtonHidden;
@property (nonatomic) BOOL unreadIconHidden;

@end
