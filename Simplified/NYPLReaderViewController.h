@interface NYPLReaderViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle NS_UNAVAILABLE;

// designated initializer
// |bookIdentifier| must not be nil.
- (instancetype)initWithBookIdentifier:(NSString *)bookIdentifier;

@end
