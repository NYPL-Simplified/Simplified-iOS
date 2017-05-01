@class NYPLBookDetailDownloadingView;

@interface NYPLBookDetailDownloadingView : UIView

@property (nonatomic) double downloadProgress;
@property (nonatomic) BOOL downloadStarted;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end
