#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsyncData.h"
#import "NYPLCatalogAcquisition.h"
#import "NYPLCatalogBook.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogSubsectionLink.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLOPDSType.h"

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
   completionHandler:^(NSData *const data) {
     if(!data) {
       NYPLLOG(@"Failed to download data.");
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                      ^{handler(nil);});
       return;
     }
     
     SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
     if(!document) {
       NYPLLOG(@"Failed to parse data as XML.");
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                      ^{handler(nil);});
       return;
     }
     
     NYPLOPDSFeed *const navigationFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];
     if(!navigationFeed) {
       NYPLLOG(@"Could not interpret XML as OPDS.");
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                      ^{handler(nil);});
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
          NYPLCatalogSubsectionLink *subsectionLink = nil;
          
          for(NYPLOPDSLink *const link in navigationEntry.links) {
            if([link.rel isEqualToString:NYPLOPDSRelationRecommended]) {
              if(!NYPLOPDSTypeStringIsAcquisition(link.type)) {
                NYPLLOG(@"Ignoring recommended feed without acquisition type.");
              } else {
                recommendedURL = link.href;
              }
            }
            if([link.rel isEqualToString:NYPLOPDSRelationSubsection]) {
              if(NYPLOPDSTypeStringIsAcquisition(link.type)) {
                subsectionLink = [[NYPLCatalogSubsectionLink alloc]
                                  initWithType:NYPLCatalogSubsectionLinkTypeAcquisition
                                  url:link.href];
              } else if(NYPLOPDSTypeStringIsNavigation(link.type)) {
                subsectionLink = [[NYPLCatalogSubsectionLink alloc]
                                  initWithType:NYPLCatalogSubsectionLinkTypeNavigation
                                  url:link.href];
              } else {
                NYPLLOG(@"Ignoring subsection without known type.");
              }
            }
          }
          
          if(!subsectionLink) {
            NYPLLOG(@"Discarding entry without subsection.");
            continue;
          }
          
          if(!recommendedURL) {
            NYPLLOG(@"Creating lane without recommended books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          id const recommendedDataObject = dataDictionary[recommendedURL];
          if([recommendedDataObject isKindOfClass:[NSNull class]]) {
            NYPLLOG(@"Creating lane without unobtainable recommended books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NSData *const recommendedData = recommendedDataObject;
          assert([recommendedData isKindOfClass:[NSData class]]);
          
          SMXMLDocument *const document = [SMXMLDocument documentWithData:recommendedData
                                                                    error:NULL];
          if(!document) {
            NYPLLOG(@"Creating lane without unparsable recommended books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NYPLOPDSFeed *recommendedAcquisitionFeed =
            [[NYPLOPDSFeed alloc] initWithDocument:document];
          
          if(!recommendedAcquisitionFeed) {
            NYPLLOG(@"Creating lane without invalid recommended books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
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
            subsectionLink:subsectionLink
            title:navigationEntry.title]];
        }
        
        NYPLCatalogRoot *const root = [[NYPLCatalogRoot alloc] initWithLanes:lanes];
        assert(root);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(root);});
      }];
   }];
}

- (instancetype)initWithLanes:(NSArray *const)lanes
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
