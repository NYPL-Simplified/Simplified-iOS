#import "NYPLRemoteViewController.h"

@interface NYPLCatalogFeedViewController : NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *)URL;
- (void) reloadCatalogue;

@end
