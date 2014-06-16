#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsyncData.h"
#import "NYPLCatalogLane.h"
#import "NYPLOPDSFeed.h"

#import "NYPLCatalogRoot.h"

@interface NYPLCatalogRoot ()

@property (nonatomic) NSArray *lanes;

@end

@implementation NYPLCatalogRoot

+ (void)withURL:(NSURL *const)url
        handler:(void (^ const)(NYPLCatalogRoot *root))handler
{
  if(!(url && handler)) {
    @throw NSInvalidArgumentException;
  }
  
  [NYPLAsyncData
   withURL:url
   completionHandler:^(NSData *data) {
     if(!data) {
       NSLog(@"NYPLCatalogRoot: Failed to download data.");
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
     if(!document) {
       NSLog(@"NYPLCatalogRoot: Failed to parse data as XML.");
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     NYPLOPDSFeed *const navigationFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];
     if(!navigationFeed) {
       NSLog(@"NYPLCatalogRoot: Could not interpret XML as OPDS.");
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     // TODO: Load acquisition feeds!
   }];
}

- (id)initWithLanes:(NSArray *const)lanes
{
  self = [super init];
  if(!self) return nil;
  
  if(!lanes) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in lanes) {
    if(![object isKindOfClass:[NYPLCatalogLane class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.lanes = lanes;
  
  return self;
}

@end
