#import "NYPLBook.h"
#import "NYPLBookCell.h"

typedef NS_ENUM(NSInteger, NYPLBookNormalCellState) {
  NYPLBookNormalCellStateUnregistered,
  NYPLBookNormalCellStateDownloadNeeded,
  NYPLBookNormalCellStateDownloadSuccessful
};

@class NYPLBookNormalCell;

@protocol NYPLBookNormalCellDelegate

- (void)didSelectDeleteForBookNormalCell:(NYPLBookNormalCell *)cell;
- (void)didSelectDownloadForBookNormalCell:(NYPLBookNormalCell *)cell;
- (void)didSelectReadForBookNormalCell:(NYPLBookNormalCell *)cell;

@end

@interface NYPLBookNormalCell : NYPLBookCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookNormalCellDelegate> delegate;
@property (nonatomic) NYPLBookNormalCellState state;

@end
