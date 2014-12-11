#import "NYPLDismissibleViewController.h"

@class NYPLBook;

@interface NYPLBookDetailViewController : NYPLDismissibleViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

// This is will do a push transition on an iPhone and a modal presentation on an iPad.
- (void)presentFromViewController:(UIViewController *)viewController;

@end
