@class NYPLBookDetailDownloadingView;

@protocol NYPLBookDetailDownloadingViewDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(NYPLBookDetailDownloadingView *)bookDetailDownloadingView;

@end

@interface NYPLBookDetailDownloadingView : UIView

@property (nonatomic, weak) id<NYPLBookDetailDownloadingViewDelegate> delegate;
@property (nonatomic) double downloadProgress;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithWidth:(CGFloat)width;

@end
