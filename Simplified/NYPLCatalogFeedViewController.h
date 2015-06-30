#import "NYPLRemoteViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NYPLCatalogFeedViewController : NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *)URL
completionHandler:(UIViewController *__nullable (^)(NSData *))handler NS_UNAVAILABLE;

// FIXME: This should take a title as well.
- (instancetype)initWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END