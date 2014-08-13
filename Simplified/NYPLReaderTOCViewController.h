@class NYPLReaderTOCViewController;
@class RDNavigationElement;

@protocol NYPLReaderTOCViewControllerDelegate

@end

@interface NYPLReaderTOCViewController : UIViewController

@property (nonatomic, weak) id<NYPLReaderTOCViewControllerDelegate> delegate;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle NS_UNAVAILABLE;

- (instancetype)initWithNavigationElement:(RDNavigationElement *)navigationElement;

@end
