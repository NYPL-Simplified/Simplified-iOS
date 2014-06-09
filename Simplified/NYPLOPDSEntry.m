#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSLink.h"
#import "SMXMLElement+NYPLElementAdditions.h"

#import "NYPLOPDSEntry.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSArray *authorNames;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSEntry

- (id)initWithElement:(SMXMLElement *const)element
{
  self = [super init];
  if(!self) return nil;

  {
    NSMutableArray *const authorNames = [NSMutableArray array];
    
    for(SMXMLElement *const authorElement in [element childrenNamed:@"author"]) {
      SMXMLElement *const nameElement = [authorElement childNamed:@"name"];
      if(!nameElement) {
        NSLog(@"NYPLOPDSEntry: 'author' element missing required 'name' element.");
        NSLog(@"NYPLOPDSEntry: Ignoring malformed 'author' element.");
        continue;
      }
      [authorNames addObject:nameElement.valueString];
    }

    self.authorNames = authorNames;
  }
  
  if(!((self.identifier = [element childNamed:@"id"].valueString))) {
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
  
  if(!((self.title = [element childNamed:@"title"].valueString))) {
    NSLog(@"NYPLOPDSEntry: Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [element childNamed:@"updated"].valueString;
    if(!updatedString) {
      NSLog(@"NYPLOPDSEntry: Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339:updatedString];
    if(!self.updated) {
      NSLog(@"NYPLOPDSEntry: Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }
  
  return self;
}

@end
