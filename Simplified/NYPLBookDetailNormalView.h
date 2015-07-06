@class NYPLBook;
@class NYPLBookDetailNormalView;

typedef NS_ENUM(NSInteger, NYPLBookDetailNormalViewState) {
  NYPLBookDetailNormalViewStateCanBorrow,
  NYPLBookDetailNormalViewStateCanKeep,
  NYPLBookDetailNormalViewStateDownloadNeeded,
  NYPLBookDetailNormalViewStateDownloadSuccessful,
  NYPLBookDetailNormalViewStateUsed
};

@protocol NYPLBookDetailNormalViewDelegate

- (void)didSelectDeleteForBookDetailNormalView:(NYPLBookDetailNormalView *)bookDetailNormalView;
- (void)didSelectDownloadForBookDetailNormalView:(NYPLBookDetailNormalView *)bookDetailNormalView;
- (void)didSelectReadForBookDetailNormalView:(NYPLBookDetailNormalView *)bookDetailNormalView;

@end

@interface NYPLBookDetailNormalView : UIView

@property (nonatomic, weak) id<NYPLBookDetailNormalViewDelegate> delegate;
@property (nonatomic) NYPLBookDetailNormalViewState state;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithWidth:(CGFloat)width;

@end
