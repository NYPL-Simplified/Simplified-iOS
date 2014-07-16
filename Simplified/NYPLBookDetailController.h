#import "NYPLBook.h"

@interface NYPLBookDetailController : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedController;

- (void)displayBook:(NYPLBook *)book fromViewController:(UIViewController *)controller;

@end
