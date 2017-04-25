#import "NYPLBookButtonsView.h"

@class NYPLBook;
@class NYPLBookButtonsView;

@interface NYPLBookDetailButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;


//GODO not used right now (eventually though.. once list views get updated)
@property (nonatomic) BOOL showReturnButtonIfApplicable;

@end
