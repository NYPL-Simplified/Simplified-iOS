#import "NYPLBookCellCollectionViewController.h"

@interface NYPLHoldsViewController : NYPLBookCellCollectionViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (void)updateBadge;

// designated initializer
- (instancetype)init;

@end
