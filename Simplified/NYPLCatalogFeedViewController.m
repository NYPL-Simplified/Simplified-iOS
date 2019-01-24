#import "NYPLCatalogGroupedFeed.h"
#import "NYPLCatalogGroupedFeedViewController.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLCatalogUngroupedFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLOPDS.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"
#import "NYPLSettings.h"

#import "NYPLCatalogFeedViewController.h"

@implementation NYPLCatalogFeedViewController

- (instancetype)initWithURL:(NSURL *const)URL
{
  self = [super initWithURL:URL
          completionHandler:^UIViewController *
          (NYPLRemoteViewController *const remoteViewController,
           NSData *const data,
           NSURLResponse *const response) {
            if ([response.MIMEType isEqualToString:@"application/atom+xml"]) {
              NYPLXML *const XML = [NYPLXML XMLWithData:data];
              if(!XML) {
                NYPLLOG(@"Cannot initialize due to invalid XML.");
                return nil;
              }
              NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:XML];
              if(!feed) {
                NYPLLOG(@"Cannot initialize due to XML not representing an OPDS feed.");
                return nil;
              }
              switch(feed.type) {
                case NYPLOPDSFeedTypeAcquisitionGrouped:
                  return [[NYPLCatalogGroupedFeedViewController alloc]
                          initWithGroupedFeed:[[NYPLCatalogGroupedFeed alloc]
                                               initWithOPDSFeed:feed]
                          remoteViewController:remoteViewController];
                case NYPLOPDSFeedTypeAcquisitionUngrouped:
                  return [[NYPLCatalogUngroupedFeedViewController alloc]
                          initWithUngroupedFeed:[[NYPLCatalogUngroupedFeed alloc]
                                                 initWithOPDSFeed:feed]
                          remoteViewController:remoteViewController];
                case NYPLOPDSFeedTypeInvalid:
                  NYPLLOG(@"Cannot initialize due to invalid feed.");
                  return nil;
                case NYPLOPDSFeedTypeNavigation: {
                  return [self navigationFeedWithData:XML remoteVC:remoteViewController];
                }
              }
            }
            else {
              NYPLLOG(@"Did not recieve XML atom feed, cannot initialize");
              return nil;
            }
          }];
  
  if(!self) return nil;
  
  return self;
}

// Only NavigationType Feed currently supported in the app is for two
// "Instant Classic" feeds presented based on user's age.
- (UIViewController *)navigationFeedWithData:(NYPLXML *)data remoteVC:(NYPLRemoteViewController *)vc
{
  NYPLXML *gatedXML = [data firstChildWithName:@"gate"];
  if (!gatedXML) {
    NYPLLOG(@"Cannot initialize due to lack of support for navigation feeds.");
    return nil;
  }
  
  [AgeCheck verifyCurrentAccountAgeRequirement:^(BOOL ageAboveLimit) {
    NSURL *url;
    if (ageAboveLimit) {
      url = [NSURL URLWithString:gatedXML.attributes[@"restriction-met"]];
    } else {
      url = [NSURL URLWithString:gatedXML.attributes[@"restriction-not-met"]];
    }
    [vc setURL:url];
    [vc load];
  }];
  
  return [[UIViewController alloc] init];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  
  if (settings.userHasSeenWelcomeScreen == YES) {
    [self load];
  }

  [[NYPLBookRegistry sharedRegistry] justLoad];
  UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
  if (applicationState == UIApplicationStateActive) {
    [self syncBookRegistryForNewFeed];
  } else {
    /// Performs with a delay because on a fresh launch, the application state takes
    /// a moment to accurately update. Posts the notification to keep the switching
    /// UI disabled while the sync occurs.
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];
    [self performSelector:@selector(syncBookRegistryForNewFeed) withObject:self afterDelay:2.0];
  }
}

- (void) reloadCatalogue {
  [self load];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO];
}

/// Syncs should not occur when the app is not Active. Background Fetch
/// operations are handled elsewhere.
- (void)syncBookRegistryForNewFeed {
  [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL success) {
    if (success) {
      [[NYPLBookRegistry sharedRegistry] save];
    }
  }];
}

@end
