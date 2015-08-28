#import "NYPLBookButtonsView.h"
@class NYPLBook;

@interface NYPLBookDetailNormalView : UIView

@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) NYPLBook *book;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithWidth:(CGFloat)width;

@end
