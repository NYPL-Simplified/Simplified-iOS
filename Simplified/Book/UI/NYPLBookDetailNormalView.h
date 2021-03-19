#import "NYPLBookButtonsState.h"
@class NYPLBook;

@interface NYPLBookDetailNormalView : UIView

@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) NYPLBook *book;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end
