#import "NYPLBookButtonsView.h"

@class NYPLBook;

@interface NYPLBookDetailButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;

@property (nonatomic) BOOL showReturnButtonIfApplicable;

@end
