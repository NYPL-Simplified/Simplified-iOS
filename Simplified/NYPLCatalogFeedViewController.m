#import "NYPLCatalogNavigationFeedViewController.h"
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
              case NYPLOPDSFeedTypeAcquisitionGrouped:
                NSLog(@"XXX: Unsupported groups feed!");
              case NYPLOPDSFeedTypeAcquisitionUngrouped:
                NSLog(@"XXX: Unsupported ungrouped feed!");
              case NYPLOPDSFeedTypeEmpty:
                NSLog(@"XXX: Unsupported empty feed!");
              case NYPLOPDSFeedTypeInvalid:
                return nil;
              case NYPLOPDSFeedTypeNavigation:
                NSLog(@"XXX: Using old navigation feed hack.");
                return [[NYPLCatalogNavigationFeedViewController alloc]
                        initWithURL:URL title:@"Catalog"];
            }
          }];
  
  if(!self) return nil;
  
  return self;
}

@end

NS_ASSUME_NONNULL_END