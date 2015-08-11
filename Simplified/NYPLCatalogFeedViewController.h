#import "NYPLRemoteViewController.h"

@interface NYPLCatalogFeedViewController : NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *)URL
completionHandler:(UIViewController *(^)(NYPLRemoteViewController *remoteViewController,
                                         NSData *data))handler NS_UNAVAILABLE;

// FIXME: This should take a title as well.
- (instancetype)initWithURL:(NSURL *)URL;
- (void) reloadCatalogue;

@end