#import "NYPLBookButtonsState.h"

@class NYPLBook;
@class NYPLBookDetailButtonsView;
@class NYPLBookDetailDownloadFailedView;

@protocol NYPLBookButtonsDelegate

- (void)didSelectReturnForBook:(NYPLBook *)book;
- (void)didSelectDownloadForBook:(NYPLBook *)book;
- (void)didSelectReadForBook:(NYPLBook *)book;

@end

@protocol NYPLBookDownloadCancellationDelegate

- (void)didSelectCancelForBookDetailDownloadingView:(NYPLBookDetailButtonsView *)view;
- (void)didSelectCancelForBookDetailDownloadFailedView:(NYPLBookDetailButtonsView *)failedView;

@end

/// This view class handles the buttons for managing a book all in one place,
/// because that's always identical and used in book cells and book detail views.
@interface NYPLBookDetailButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
@property (nonatomic, weak) id<NYPLBookDownloadCancellationDelegate> downloadingDelegate;
@property (nonatomic) BOOL showReturnButtonIfApplicable;

- (void)configureForBookDetailsContext;

@end
