#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSLink.h"
#import "SMXMLElement+NYPLElementAdditions.h"

#import "NYPLOPDSEntry.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *summary;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSEntry

- (instancetype)initWithElement:(SMXMLElement *const)element
{
  self = [super init];
  if(!self) return nil;

  {
    NSMutableArray *const authorStrings = [NSMutableArray array];
    
    for(SMXMLElement *const authorElement in [element childrenNamed:@"author"]) {
      SMXMLElement *const nameElement = [authorElement childNamed:@"name"];
      if(!nameElement) {
        NYPLLOG(@"'author' element missing required 'name' element.");
        NYPLLOG(@"Ignoring malformed 'author' element.");
        continue;
      }
      [authorStrings addObject:nameElement.valueString];
    }

    self.authorStrings = authorStrings;
  }
  
  if(!((self.identifier = [element childNamed:@"id"].valueString))) {
    NYPLLOG(@"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(SMXMLElement *const linkElement in [element childrenNamed:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithElement:linkElement];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  self.summary = [element childNamed:@"summary"].value;
  
  if(!((self.title = [element childNamed:@"title"].valueString))) {
    NYPLLOG(@"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [element childNamed:@"updated"].valueString;
    if(!updatedString) {
      NYPLLOG(@"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339String:updatedString];
    if(!self.updated) {
      NYPLLOG(@"Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }
  
  return self;
}

@end
