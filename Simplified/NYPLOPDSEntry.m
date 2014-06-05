#import "NSDate+NYPLDateAdditions.h"

#import "NYPLOPDSEntry.h"
#import "NYPLOPDSLink.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSArray *authorNames;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSEntry

- (id)initWithElement:(SMXMLElement *)element
{
  self = [super init];
  if(!self) return nil;

  {
    NSMutableArray *const authorNames = [NSMutableArray array];
    
    for(SMXMLElement *const authorElement in [element childrenNamed:@"author"]) {
      NSString *const name = [authorElement childNamed:@"name"].value;
      if(!name) {
        NSLog(@"NYPLOPDSEntry: 'author' element missing required 'name' element.");
        NSLog(@"NYPLOPDSEntry: Ignoring malformed 'author' element.");
        continue;
      }
      [authorNames addObject:name];
    }
    
    self.authorNames = authorNames;
  }
  
  if(!((self.identifier = [element childNamed:@"id"].value))) {
    NSLog(@"NYPLOPDSEntry: Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(SMXMLElement *const linkElement in [element childrenNamed:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithElement:linkElement];
      if(!link) {
        NSLog(@"NYPLOPDSEntry: Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  if(!((self.title = [element childNamed:@"title"].value))) {
    NSLog(@"NYPLOPDSEntry: Missing required 'title' element.");
    return nil;
  }
  
  if(!((self.updated = [NSDate dateWithRFC3339:[element childNamed:@"updated"].value]))) {
    NSLog(@"NYPLOPDSAcquisitionFeed: Missing required 'updated' element.");
    return nil;
  }
  
  return self;
}

@end
