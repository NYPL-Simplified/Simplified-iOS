#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsyncData.h"
#import "NYPLCatalogLane.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"

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
  
  // TODO: Some parts of this do not need to happen on the main thread. It may be worth changing
  // NYPLAsyncData to allow running some of this elsewhere.
  
  [NYPLAsyncData
   withURL:url
   completionHandler:^(NSData *const data) {
     if(!data) {
       NSLog(@"%@: Failed to download data.", [self class]);
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
     if(!document) {
       NSLog(@"%@: Failed to parse data as XML.", [self class]);
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     NYPLOPDSFeed *const navigationFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];
     if(!navigationFeed) {
       NSLog(@"%@: Could not interpret XML as OPDS.", [self class]);
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         handler(nil);
       }];
       return;
     }
     
     NSMutableSet *const recommendedURLs =
       [NSMutableSet setWithCapacity:navigationFeed.entries.count];
     
     for(NYPLOPDSEntry *const entry in navigationFeed.entries) {
       for(NYPLOPDSLink *const link in entry.links) {
         if([link.rel isEqualToString:NYPLOPDSRelationRecommended]) {
           [recommendedURLs addObject:link.href];
         }
       }
     }
     
     [NYPLAsyncData
      withURLSet:recommendedURLs
      completionHandler:^(NSDictionary *const dataDictionary) {
        NSMutableArray *const lanes =
          [NSMutableArray arrayWithCapacity:navigationFeed.entries.count];
        
        for(NYPLOPDSEntry *const entry in navigationFeed.entries) {
          NSURL *recommendedURL = nil;
          NSURL *subsectionURL = nil;
          
          for(NYPLOPDSLink *const link in entry.links) {
            if([link.rel isEqualToString:NYPLOPDSRelationRecommended]) {
              recommendedURL = link.href;
            }
            if([link.rel isEqualToString:NYPLOPDSRelationSubsection]) {
              subsectionURL = link.href;
            }
          }
          
          if(!subsectionURL) {
            NSLog(@"%@: Discarding entry without subsection.", [self class]);
            continue;
          }
          
          if(!recommendedURL) {
            NSLog(@"%@: Creating lane without recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:entry.title]];
            continue;
          }
          
          id const recommendedDataObject = [dataDictionary objectForKey:recommendedURL];
          if([recommendedDataObject isKindOfClass:[NSNull class]]) {
            NSLog(@"%@: Creating lane without unobtainable recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:entry.title]];
            continue;
          }
          
          NSData *const recommendedData = recommendedDataObject;
          assert([recommendedData isKindOfClass:[NSData class]]);
          
          SMXMLDocument *const document = [SMXMLDocument documentWithData:recommendedData
                                                                    error:NULL];
          if(!document) {
            NSLog(@"%@: Creating lane without unparsable recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:entry.title]];
            continue;
          }
          
          NYPLOPDSFeed *recommendedFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];
          if(!recommendedFeed) {
            NSLog(@"%@: Creating lane without invalid recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:entry.title]];
            continue;
          }
          
          // TODO: Create lane WITH recommended books here!
        }
      }];
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
