#import "NYPLBook.h"

@interface NYPLBookDetailController : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBook:(NYPLBook *)book;

- (void)displayFromViewController:(UIViewController *)controller;

@end
