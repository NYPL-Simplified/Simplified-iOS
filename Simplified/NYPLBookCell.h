#import "NYPLBook.h"

CGSize NYPLBookCellSizeForIdiomAndOrientation(UIUserInterfaceIdiom idiom,
                                              UIInterfaceOrientation orientation);

typedef NS_ENUM(NSInteger, NYPLBookCellState) {
  NYPLBookCellStateUnregistered,
  NYPLBookCellStateDownloadNeeded,
  NYPLBookCellStateDownloadSuccessful
};

@class NYPLBookCell;

@protocol NYPLBookCellDelegate

- (void)didSelectDeleteForBookCell:(NYPLBookCell *)cell;
- (void)didSelectDownloadForBookCell:(NYPLBookCell *)cell;
- (void)didSelectReadForBookCell:(NYPLBookCell *)cell;

@end

@interface NYPLBookCell : UICollectionViewCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookCellDelegate> delegate;
@property (nonatomic) NYPLBookCellState state;

@end
