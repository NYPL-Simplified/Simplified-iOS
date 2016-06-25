#import "NYPLCatalogGroupedFeed.h"
#import "NYPLCatalogGroupedFeedViewController.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLCatalogUngroupedFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLOPDS.h"
#import "NYPLXML.h"

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
                case NYPLOPDSFeedTypeNavigation:
                  NYPLLOG(@"Cannot initialize due to lack of support for navigation feeds.");
                  return nil;
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

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self load];
}

- (void) reloadCatalogue {
  [self load];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self.navigationController setNavigationBarHidden:NO];
}

@end