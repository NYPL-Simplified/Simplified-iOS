#import "NSDate+NYPLDateAdditions.h"
#import "NYPLAsync.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSLink.h"
#import "NYPLSession.h"
#import "NYPLXML.h"

#import "NYPLOPDSFeed.h"

@interface NYPLOPDSFeed ()

@property (nonatomic) NSArray *entries;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSFeed

+ (void)withURL:(NSURL *)URL completionHandler:(void (^)(NYPLOPDSFeed *feed))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLSession sharedSession] withURL:URL completionHandler:^(NSData *data) {
    if(!data) {
      NYPLLOG(@"Failed to retrieve data.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    NYPLXML *const feedXML = [NYPLXML XMLWithData:data];
    if(!feedXML) {
      NYPLLOG(@"Failed to parse data as XML.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:feedXML];
    if(!feed) {
      NYPLLOG(@"Could not interpret XML as OPDS.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    NYPLAsyncDispatch(^{handler(feed);});
  }];
}

- (instancetype)initWithXML:(NYPLXML *const)feedXML
{
  self = [super init];
  if(!self) return nil;
  
  if(!feedXML) {
    return nil;
  }
  
  if(!((self.identifier = [feedXML firstChildWithName:@"id"].value))) {
    NYPLLOG(@"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(NYPLXML *const linkXML in [feedXML childrenWithName:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  if(!((self.title = [feedXML firstChildWithName:@"title"].value))) {
    NYPLLOG(@"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [feedXML firstChildWithName:@"updated"].value;
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
  
  {
    NSMutableArray *const entries = [NSMutableArray array];
    
    for(NYPLXML *const entryXML in [feedXML childrenWithName:@"entry"]) {
      NYPLOPDSEntry *const entry = [[NYPLOPDSEntry alloc] initWithXML:entryXML];
      if(!entry) {
        NYPLLOG(@"Ingoring malformed 'entry' element.");
        continue;
      }
      [entries addObject:entry];
    }
    
    self.entries = entries;
  }
  
  return self;
}

@end
