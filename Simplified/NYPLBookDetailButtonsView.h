#import "NYPLBookButtonsView.h"

@class NYPLBook;
@class NYPLBookDetailButtonsView;

@protocol NYPLBookDetailDownloadingViewDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(NYPLBookDetailButtonsView *)bookDetailButtonsView;

@end

@interface NYPLBookDetailButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
@property (nonatomic, weak) id<NYPLBookDetailDownloadingViewDelegate> downloadingDelegate;

@property (nonatomic) BOOL showReturnButtonIfApplicable;

@end
