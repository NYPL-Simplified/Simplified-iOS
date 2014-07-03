#import "NSDate+NYPLDateAdditions.h"
#import "NYPLAsync.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSLink.h"
#import "NYPLSession.h"
#import "SMXMLElement+NYPLElementAdditions.h"

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
  [[NYPLSession sharedSession] withURL:URL completionHandler:^(NSData *data) {
    if(!data) {
      NYPLLOG(@"Failed to retrieve data.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
    if(!document) {
      NYPLLOG(@"Failed to parse data as XML.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithDocument:document];
    if(!feed) {
      NYPLLOG(@"Could not interpret XML as OPDS.");
      NYPLAsyncDispatch(^{handler(nil);});
      return;
    }
    
    NYPLAsyncDispatch(^{handler(feed);});
  }];
}

- (instancetype)initWithDocument:(SMXMLDocument *const)document
{
  self = [super init];
  if(!self) return nil;
  
  if(!document) {
    return nil;
  }
  
  if(!((self.identifier = [document.root childNamed:@"id"].valueString))) {
    NYPLLOG(@"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(SMXMLElement *const linkElement in [document.root childrenNamed:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithElement:linkElement];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  if(!((self.title = [document.root childNamed:@"title"].valueString))) {
    NYPLLOG(@"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [document.root childNamed:@"updated"].valueString;
    if(!updatedString) {
      NYPLLOG(@"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339:updatedString];
    if(!self.updated) {
      NYPLLOG(@"Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }
  
  {
    NSMutableArray *const entries = [NSMutableArray array];
    
    for(SMXMLElement *const entryElement in [document.root childrenNamed:@"entry"]) {
      NYPLOPDSEntry *const entry = [[NYPLOPDSEntry alloc] initWithElement:entryElement];
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
