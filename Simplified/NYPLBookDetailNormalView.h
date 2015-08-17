@class NYPLBook;
@class NYPLBookDetailNormalView;

typedef NS_ENUM(NSInteger, NYPLBookDetailNormalViewState) {
  NYPLBookDetailNormalViewStateCanBorrow,
  NYPLBookDetailNormalViewStateCanHold,
  NYPLBookDetailNormalViewStateCanKeep,
  NYPLBookDetailNormalViewStateHolding,
  NYPLBookDetailNormalViewStateHoldingFOQ, // Front Of Queue
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
@property (nonatomic) NSDate *date; // nilable - hold or borrow expiry, or estimated time until you can borrow

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithWidth:(CGFloat)width;

@end
