#import "NYPLBookCellCollectionViewController.h"

@protocol LibraryModuleDelegate;

@interface NYPLMyBooksViewController : NYPLBookCellCollectionViewController

@property (weak) id<LibraryModuleDelegate> libraryDelegate;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// designated initializer
- (instancetype)init;

@end
