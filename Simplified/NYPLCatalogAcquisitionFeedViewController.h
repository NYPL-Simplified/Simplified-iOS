#import "NYPLBookCellCollectionViewController.h"

@interface NYPLCatalogAcquisitionFeedViewController : NYPLBookCellCollectionViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithURL:(NSURL *const)URL title:(NSString *const)title;

@end
