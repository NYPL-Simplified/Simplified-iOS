#import "NYPLCatalogGroupedFeed.h"
#import "NYPLCatalogGroupedFeedViewController.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLCatalogUngroupedFeedViewController.h"
#import "NYPLOPDS.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"
#import "NYPLCatalogFeedViewController.h"

@implementation NYPLCatalogFeedViewController

- (instancetype)initWithURL:(NSURL *const)URL
{
  self = [super initWithURL:URL
                    handler:^UIViewController *(NYPLRemoteViewController *remoteVC,
                                                NSData *data,
                                                NSURLResponse *response) {

    return [NYPLCatalogFeedViewController makeWithRemoteVC:remoteVC
                                                      data:data
                                               urlResponse:response];
  }];

  NYPLLOG_F(@"init'ing %@ with URL: %@", self, URL);

  return self;
}

- (void)dealloc
{
  NYPLLOG_F(@"dealloc %@", self);
}

+ (UIViewController*)makeWithRemoteVC:(NYPLRemoteViewController *)remoteVC
                                 data:(NSData*)data
                          urlResponse:(NSURLResponse*)response
{
  if (![response.MIMEType isEqualToString:@"application/atom+xml"]) {
    NYPLLOG(@"Did not receive XML atom feed, cannot initialize");
    [NYPLErrorLogger
     logCatalogInitErrorWithCode:NYPLErrorCodeInvalidResponseMimeType
     response:response metadata:nil];
    return nil;
  }

  NYPLXML *const XML = [NYPLXML XMLWithData:data];
  if(!XML) {
    NYPLLOG(@"Cannot initialize due to invalid XML.");
    [NYPLErrorLogger
     logCatalogInitErrorWithCode:NYPLErrorCodeInvalidXML
     response:response metadata:nil];
    return nil;
  }

  NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:XML];
  if(!feed) {
    NYPLLOG(@"Cannot initialize due to XML not representing an OPDS feed.");
    [NYPLErrorLogger
     logCatalogInitErrorWithCode:NYPLErrorCodeOpdsFeedParseFail
     response:response metadata:nil];
    return nil;
  }

  switch(feed.type) {
    case NYPLOPDSFeedTypeAcquisitionGrouped:
      return [[NYPLCatalogGroupedFeedViewController alloc]
              initWithGroupedFeed:[[NYPLCatalogGroupedFeed alloc]
                                   initWithOPDSFeed:feed]
              remoteViewController:remoteVC];
    case NYPLOPDSFeedTypeAcquisitionUngrouped:
      return [[NYPLCatalogUngroupedFeedViewController alloc]
              initWithUngroupedFeed:[[NYPLCatalogUngroupedFeed alloc]
                                     initWithOPDSFeed:feed]
              remoteViewController:remoteVC];
    case NYPLOPDSFeedTypeInvalid:
      NYPLLOG(@"Cannot initialize due to invalid feed.");
      [NYPLErrorLogger
       logCatalogInitErrorWithCode:NYPLErrorCodeInvalidFeedType
       response:response
       metadata:@{ @"feedType": @(feed.type)}];
      return nil;
    case NYPLOPDSFeedTypeNavigation: {
      return [NYPLCatalogFeedViewController navigationFeedWithData:XML
                                                          remoteVC:remoteVC];
    }
  }
}

// Only NavigationType Feed currently supported in the app is for two
// "Instant Classic" feeds presented based on user's age.
+ (UIViewController *)navigationFeedWithData:(NYPLXML *)data
                                    remoteVC:(NYPLRemoteViewController *)remoteVC
{
  NYPLXML *gatedXML = [data firstChildWithName:@"gate"];
  if (!gatedXML) {
    NYPLLOG(@"Cannot initialize due to lack of support for navigation feeds.");
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoAgeGateElement
                              summary:@"Data received from Server lacks `gate` element for age-check."
                             metadata:nil];
    return nil;
  }

  [[[AccountsManager shared] ageCheck] verifyCurrentAccountAgeRequirementWithUserAccountProvider:[NYPLUserAccount sharedAccount]
                                                                   currentLibraryAccountProvider:[AccountsManager shared]
                                                                                      completion:^(BOOL ageAboveLimit) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSURL *url;
      if (ageAboveLimit) {
        url = [NSURL URLWithString:gatedXML.attributes[@"restriction-met"]];
      } else {
        url = [NSURL URLWithString:gatedXML.attributes[@"restriction-not-met"]];
      }
      if (url != nil) {
        [remoteVC loadWithURL:url];
      } else {
        [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                                  summary:@"Server response for age verification lacks a URL to load."
                                 metadata:@{
                                   @"ageAboveLimit": @(ageAboveLimit),
                                   @"gateElementXMLAttributes": gatedXML.attributes,
                                 }];
        [remoteVC showReloadViewWithMessage:NSLocalizedString(@"This URL cannot be found. Please close the app entirely and reload it. If the problem persists, please contact your library's Help Desk.", @"Generic error message indicating that the URL the user was trying to load is missing.")];
      }
    });
  }];

  return [[UIViewController alloc] init];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([self shouldLoad]) {
    [self load];
  }

  [[NYPLBookRegistry sharedRegistry] justLoad];
  UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
  if (applicationState == UIApplicationStateActive) {
    [self syncBookRegistryForNewFeed];
  } else {
    /// Performs with a delay because on a fresh launch, the application state takes
    /// a moment to accurately update.
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncBegan object:nil];
    [self performSelector:@selector(syncBookRegistryForNewFeed) withObject:self afterDelay:2.0];
  }
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO];
}

/// Only sync the book registry for a new feed if the app is in the active state.
- (void)syncBookRegistryForNewFeed
{
  UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
  if (applicationState == UIApplicationStateActive) {
    [[NYPLBookRegistry sharedRegistry] syncResettingCache:NO completionHandler:^(NSDictionary *errorDict) {
      if (errorDict == nil) {
        [[NYPLBookRegistry sharedRegistry] save];
      }
    }];
  }
}

@end
