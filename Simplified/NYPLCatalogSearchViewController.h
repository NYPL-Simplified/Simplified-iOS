@interface NYPLCatalogSearchViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithCategoryTitle:(NSString *)categoryTitle
                       searchTemplate:(NSString *)searchTemplate;

@end
