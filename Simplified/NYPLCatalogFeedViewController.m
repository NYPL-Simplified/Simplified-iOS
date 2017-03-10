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
                                               initWithOPDSFeed:feed]];
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
//    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

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
//    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

  }
}

- (void) reloadCatalogue {
  [self load];
//  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self.navigationController setNavigationBarHidden:NO];
}

@end
