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
              NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:XML];
              NSString *feedcat = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] substringToIndex:100];
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
                  NYPLLOG(@"warning", kNYPLInvalidFeedException, @{@"feed":feedcat}, @"Cannot initialize due to invalid feed.");
                  return nil;
                case NYPLOPDSFeedTypeNavigation:
                  NYPLLOG(@"warning", kNYPLInvalidFeedException, @{@"feed":feedcat}, @"Cannot initialize due to lack of support for navigation feeds.");
                  return nil;
              }
            }
            else {
              NYPLLOG(@"warning", kNYPLInvalidFeedException, nil, @"Did not revceive XML atom feed, cannot initialize");
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