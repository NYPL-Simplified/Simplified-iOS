@class NYPLBookDetailDownloadFailedView;

@protocol NYPLBookDetailDownloadFailedViewDelegate

- (void)didSelectCancelForBookDetailDownloadFailedView:
(NYPLBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView;

- (void)didSelectTryAgainForBookDetailDownloadFailedView:
(NYPLBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView;

@end

@interface NYPLBookDetailDownloadFailedView : UIView

@property (nonatomic, weak) id<NYPLBookDetailDownloadFailedViewDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithWidth:(CGFloat)width;

@end
