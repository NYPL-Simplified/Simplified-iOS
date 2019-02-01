@interface NYPLReaderViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle NS_UNAVAILABLE;

@property (nonatomic, readonly) NSString *bookIdentifier;

// designated initializer
// |bookIdentifier| must not be nil. The book associated with the identifier given will be marked
// as used in the book registry.
- (instancetype)initWithBookIdentifier:(NSString *)bookIdentifier;

@end
