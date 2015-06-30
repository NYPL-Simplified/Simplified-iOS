#import "NYPLCatalogGroupedFeed.h"
#import "NYPLCatalogGroupedFeedViewController.h"
#import "NYPLOPDS.h"
#import "NYPLXML.h"

#import "NYPLCatalogFeedViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NYPLCatalogFeedViewController

- (instancetype)initWithURL:(NSURL *const)URL
{
  self = [super initWithURL:URL
          completionHandler:^UIViewController *__nonnull (NSData *const data) {
            NYPLXML *const XML = [NYPLXML XMLWithData:data];
            NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:XML];
            switch(feed.type) {
              case NYPLOPDSFeedTypeAcquisitionGrouped: {
                return [[NYPLCatalogGroupedFeedViewController alloc]
                        initWithGroupedFeed:[[NYPLCatalogGroupedFeed alloc]
                                             initWithOPDSFeed:feed]];
              }
              case NYPLOPDSFeedTypeAcquisitionUngrouped:
                NSLog(@"XXX: Unsupported ungrouped feed!");
                return nil;
              case NYPLOPDSFeedTypeEmpty:
                NSLog(@"XXX: Unsupported empty feed!");
                return nil;
              case NYPLOPDSFeedTypeInvalid:
                NYPLLOG(@"Cannot initialize due to invalid feed.");
                return nil;
              case NYPLOPDSFeedTypeNavigation:
                NYPLLOG(@"Cannot initialize due to lack of support for navigation feeds.");
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

@end

NS_ASSUME_NONNULL_END