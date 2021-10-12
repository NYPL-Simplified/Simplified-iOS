#import "NYPLBookButtonsState.h"

@class NYPLBook;
@class NYPLBookButtonsView;
@class NYPLBookDetailDownloadFailedView;

@protocol NYPLBookButtonsDelegate

- (void)didSelectReturnForBook:(NYPLBook *)book;
- (void)didSelectDownloadForBook:(NYPLBook *)book;
- (void)didSelectReadForBook:(NYPLBook *)book successCompletion:(void(^)(void))completion;

@end

@protocol NYPLBookDownloadCancellationDelegate

- (void)didSelectCancelForBookDetailDownloadingView:(NYPLBookButtonsView *)view;
- (void)didSelectCancelForBookDetailDownloadFailedView:(NYPLBookButtonsView *)failedView;

@end

/// This view class handles the buttons for managing a book all in one place,
/// because that's always identical and used in book cells and book detail views.
@interface NYPLBookButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
@property (nonatomic, weak) id<NYPLBookDownloadCancellationDelegate> downloadingDelegate;

- (void)configureForBookDetailsContext;
- (void)setReadButtonAccessibilityLabelWithMessage:(NSString *) message;

@end
