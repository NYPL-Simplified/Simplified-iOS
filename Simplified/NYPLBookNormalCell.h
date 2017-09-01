#import "NYPLBookCell.h"
#import "NYPLBookButtonsView.h"

@class NYPLBook;
@class NYPLBookNormalCell;

@interface NYPLBookNormalCell : NYPLBookCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;

@property (nonatomic) UIImageView *cover;

@end
