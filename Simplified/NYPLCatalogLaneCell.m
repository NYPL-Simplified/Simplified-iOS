#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLURLSetSession.h"

#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property volatile int32_t imageDownloadsRemaining;
@property (atomic) NSMutableArray *coverImages;

@end

@implementation NYPLCatalogLaneCell

- (id)initWithEntry:(NYPLOPDSEntry *const)entry
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 200, 20)];
  titleLabel.text = entry.title;
  [self addSubview:titleLabel];

  NSUInteger const index = [entry.links indexOfObjectPassingTest:
                            ^BOOL(id const obj, __attribute__((unused)) NSUInteger i, BOOL *stop) {
                              NSString *rel = ((NYPLOPDSLink *) obj).rel;
                              if([rel isEqualToString:@"http://opds-spec.org/recommended"]) {
                                *stop = YES;
                                return YES;
                              }
                              return NO;
                            }];
  
  if(index != NSNotFound) {
    [self downloadRecommendedFeed:((NYPLOPDSLink *) entry.links[index]).href];
  }
  
  return self;
}

- (void)downloadRecommendedFeed:(NSURL *const)url
{
  [[[NSURLSession sharedSession]
    dataTaskWithRequest:[NSURLRequest requestWithURL:url]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      if(error) {
        NSLog(@"NYPLCatalogLaneCell: Failed to download recommended feed.");
        return;
      }
      SMXMLDocument *document = [[SMXMLDocument alloc] initWithData:data error:NULL];
      NYPLOPDSFeed *feed = [[NYPLOPDSFeed alloc] initWithDocument:document];
      if(!feed) {
        NSLog(@"NYPLCatalogLaneCell: Failed to load recommended feed.");
        return;
      }
      [self downloadImagesForFeed:feed];
    }]
   resume];
}

- (void)downloadImagesForFeed:(NYPLOPDSFeed *const)feed
{
  NSMutableSet *const imageURLs = [NSMutableSet set];
  
  for(NYPLOPDSEntry *const entry in feed.entries) {
    for(NYPLOPDSLink *const link in entry.links) {
      if([link.rel isEqualToString:@"http://opds-spec.org/image"]) {
        [imageURLs addObject:link.href];
        break;
      }
    }
  }
  
  __attribute__((unused)) NYPLURLSetSession *setSession =
    [[NYPLURLSetSession alloc]
     initWithURLSet:imageURLs
     completionHandler:^(NSDictionary *const dataDictionary) {
       NSLog(@"(%d) %@", dataDictionary.count, feed.title);
     }];
}

@end
