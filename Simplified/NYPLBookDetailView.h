#import "NYPLBook.h"

@interface NYPLBookDetailView : UIView

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book coverImage:(UIImage *)coverImage frame:(CGRect)frame;

@end
