#import "NYPLBookCell.h"
#import "NYPLBookButtonsState.h"

@class NYPLBook;
@class NYPLBookNormalCell;
@protocol NYPLBookButtonsDelegate;

@interface NYPLBookNormalCell : NYPLBookCell

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;

@property (nonatomic) UIImageView *cover;

@end
