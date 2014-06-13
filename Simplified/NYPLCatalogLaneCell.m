// TODO: Non-retina devices should probably load thumbnail images.
// TODO: General code refactoring is required.

#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLURLSetSession.h"

#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property (nonatomic) UIScrollView *scrollView;

@end

@implementation NYPLCatalogLaneCell

- (id)initWithEntry:(NYPLOPDSEntry *const)entry
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:[self bounds]];
  self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  [self addSubview:self.scrollView];
  
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
      SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
      NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithDocument:document];
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
  
  __attribute__((unused)) NYPLURLSetSession *const setSession =
    [[NYPLURLSetSession alloc]
     initWithURLSet:imageURLs
     completionHandler:^(NSDictionary *const dataDictionary) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         [self displayImageData:dataDictionary forFeed:feed];
       }];
     }];
}

- (void)displayImageData:(NSDictionary *)dataDictionary forFeed:(NYPLOPDSFeed *)feed
{
  CGFloat const height = 125;
  CGFloat x = 0;
  
  for(NYPLOPDSEntry *const entry in feed.entries) {
    for(NYPLOPDSLink *const link in entry.links) {
      if([link.rel isEqualToString:@"http://opds-spec.org/image"]) {
        id dataOrError = [dataDictionary objectForKey:link.href];
        if([dataOrError isKindOfClass:[NSError class]]) {
          NSLog(@"%@", dataOrError);
          break;
        }
        NSData *const data = dataOrError;
        UIImage *const image = [UIImage imageWithData:data];
        UIImageView *const imageView = [[UIImageView alloc] initWithImage:image];
        if(image.size.height >= height && image.size.width < image.size.height * 1.5) {
          CGFloat const width = height * image.size.width / image.size.height;
          imageView.frame = CGRectMake(x + 5, 0, width, height);
          x += width + 5.0;
          imageView.contentMode = UIViewContentModeScaleAspectFit;
          [self.scrollView addSubview:imageView];
        } else {
          NSLog(@"NYPLCatalogLaneCell: Not showing poor-quality cover.");
          UIImageView *const imageView = [[UIImageView alloc]
                                          initWithImage:[UIImage imageNamed:@"NoCover"]];
          CGRect frame = imageView.frame;
          frame.origin.x = x + 5.0;
          frame.origin.y = 0.0;
          imageView.frame = frame;
          x += imageView.image.size.width + 5.0;
          [self.scrollView addSubview:imageView];
        }
      }
    }
  }
  
  self.scrollView.contentSize = CGSizeMake(x + 5.0, height);
}

@end
