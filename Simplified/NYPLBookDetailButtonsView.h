#import "NYPLBookButtonsView.h"

@class NYPLBook;
@class NYPLBookDetailButtonsView;
@class NYPLBookDetailDownloadFailedView;

@protocol NYPLBookDetailDownloadingDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(NYPLBookDetailButtonsView *)bookDetailButtonsView;

- (void)didSelectCancelForBookDetailDownloadFailedView:
(NYPLBookDetailButtonsView *)NYPLBookDetailDownloadFailedView;

@end

@interface NYPLBookDetailButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
@property (nonatomic, weak) id<NYPLBookDetailDownloadingDelegate> downloadingDelegate;

@property (nonatomic) BOOL showReturnButtonIfApplicable;

@end
