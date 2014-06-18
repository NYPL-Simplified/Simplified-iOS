#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsyncData.h"
#import "NYPLCatalogAcquisition.h"
#import "NYPLCatalogBook.h"
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
  
  // TODO: None of this needs to happen on the main thread. It may be worth changing
  // NYPLAsyncData to allow running some of this elsewhere if performance is an issue.
  
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
        
        for(NYPLOPDSEntry *const navigationEntry in navigationFeed.entries) {
          NSURL *recommendedURL = nil;
          NSURL *subsectionURL = nil;
          
          for(NYPLOPDSLink *const link in navigationEntry.links) {
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
              title:navigationEntry.title]];
            continue;
          }
          
          id const recommendedDataObject = [dataDictionary objectForKey:recommendedURL];
          if([recommendedDataObject isKindOfClass:[NSNull class]]) {
            NSLog(@"%@: Creating lane without unobtainable recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:navigationEntry.title]];
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
              title:navigationEntry.title]];
            continue;
          }
          
          NYPLOPDSFeed *recommendedAcquisitionFeed =
            [[NYPLOPDSFeed alloc] initWithDocument:document];
          
          if(!recommendedAcquisitionFeed) {
            NSLog(@"%@: Creating lane without invalid recommended books.", [self class]);
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:[NSArray array]
              subsectionURL:subsectionURL
              title:navigationEntry.title]];
            continue;
          }
          
          NSMutableArray *const books =
            [NSMutableArray arrayWithCapacity:recommendedAcquisitionFeed.entries.count];
          
          for(NYPLOPDSEntry *const acquisitionEntry in recommendedAcquisitionFeed.entries) {
            NSURL *borrow, *generic, *openAccess, *sample, *image, *imageThumbnail = nil;
            for(NYPLOPDSLink *const link in acquisitionEntry.links) {
              if([link.rel isEqualToString:NYPLOPDSRelationAcquisition]) {
                generic = link.href;
                continue;
              }
              if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionBorrow]) {
                borrow = link.href;
                continue;
              }
              if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionOpenAccess]) {
                openAccess = link.href;
                continue;
              }
              if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionSample]) {
                sample = link.href;
                continue;
              }
              if([link.rel isEqualToString:NYPLOPDSRelationImage]) {
                image = link.href;
                continue;
              }
              if([link.rel isEqualToString:NYPLOPDSRelationImageThumbnail]) {
                imageThumbnail = link.href;
                continue;
              }
            }
            [books addObject:
             [[NYPLCatalogBook alloc]
              initWithAcquisition:[[NYPLCatalogAcquisition alloc]
                                   initWithBorrow:borrow
                                   generic:generic
                                   openAccess:openAccess
                                   sample:sample]
              authorStrings:acquisitionEntry.authorStrings
              identifier:acquisitionEntry.identifier
              imageURL:image
              imageThumbnailURL:imageThumbnail
              title:acquisitionEntry.title
              updated:acquisitionEntry.updated]];
          }
          
          [lanes addObject:
           [[NYPLCatalogLane alloc]
            initWithBooks:books
            subsectionURL:subsectionURL
            title:navigationEntry.title]];
        }
        
        NYPLCatalogRoot *const root = [[NYPLCatalogRoot alloc] initWithLanes:lanes];
        assert(root);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(root);
        }];
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
  
  for(id const object in lanes) {
    if(![object isKindOfClass:[NYPLCatalogLane class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.lanes = lanes;
  
  return self;
}

@end
