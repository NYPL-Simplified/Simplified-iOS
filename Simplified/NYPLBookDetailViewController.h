#import "NYPLDismissableViewController.h"

#import "NYPLBook.h"

@interface NYPLBookDetailViewController : NYPLDismissableViewController

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

// This is will do a push transition on an iPhone and a modal presentation on an iPad.
- (void)presentFromViewController:(UIViewController *)viewController;

@end
