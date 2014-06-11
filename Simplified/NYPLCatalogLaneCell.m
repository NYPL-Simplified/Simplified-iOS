#import "NYPLOPDSLink.h"

#import "NYPLCatalogLaneCell.h"

@implementation NYPLCatalogLaneCell

- (id)initWithEntry:(NYPLOPDSEntry *)entry
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 200, 20)];
  titleLabel.text = entry.title;
  [self addSubview:titleLabel];

  NSUInteger index = [entry.links indexOfObjectPassingTest:
                      ^BOOL(id const obj, __attribute__((unused)) NSUInteger i, BOOL *stop) {
                        NSString *rel = ((NYPLOPDSLink *) obj).rel;
                        if([rel isEqualToString:@"http://opds-spec.org/recommended"]) {
                          *stop = YES;
                          return YES;
                        }
                        return NO;
                      }];
  
  if(index != NSNotFound) {
    NSURL *url = [NSURL URLWithString:entry.links[index]];
    NSURLSessionDataTask *task = ...
  }
  
  return self;
}

@end
