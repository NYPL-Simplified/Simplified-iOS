#import "NYPLRemoteViewController.h"

@interface NYPLCatalogFeedViewController : NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *)URL
completionHandler:(UIViewController *(^)(NYPLRemoteViewController *remoteViewController,
                                         NSData *data))handler NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL;
- (void) reloadCatalogue;

@end