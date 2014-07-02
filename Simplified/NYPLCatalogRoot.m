#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsync.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBook.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogSubsectionLink.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLOPDSType.h"
#import "NYPLSession.h"

#import "NYPLCatalogRoot.h"

@interface NYPLCatalogRoot ()

@property (nonatomic) NSArray *lanes;

@end

@implementation NYPLCatalogRoot

+ (void)withURL:(NSURL *const)url
        handler:(void (^)(NYPLCatalogRoot *root))handler
{
  if(!(url && handler)) {
    @throw NSInvalidArgumentException;
  }
  
  [NYPLOPDSFeed
   withURL:url
   completionHandler:^(NYPLOPDSFeed *const navigationFeed) {
     if(!navigationFeed) {
       NYPLLOG(@"Failed to retrieve main navigation feed.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NSMutableSet *const featuredURLs =
       [NSMutableSet setWithCapacity:navigationFeed.entries.count];
     
     for(NYPLOPDSEntry *const entry in navigationFeed.entries) {
       for(NYPLOPDSLink *const link in entry.links) {
         if([link.rel isEqualToString:NYPLOPDSRelationFeatured]) {
           [featuredURLs addObject:link.href];
         }
       }
     }
     
     [[NYPLSession sharedSession]
      withURLs:featuredURLs handler:^(NSDictionary *const dataDictionary) {
        NSMutableArray *const lanes =
          [NSMutableArray arrayWithCapacity:navigationFeed.entries.count];
        
        for(NYPLOPDSEntry *const navigationEntry in navigationFeed.entries) {
          NSURL *featuredURL = nil;
          NYPLCatalogSubsectionLink *subsectionLink = nil;
          
          for(NYPLOPDSLink *const link in navigationEntry.links) {
            if([link.rel isEqualToString:NYPLOPDSRelationFeatured]) {
              if(!NYPLOPDSTypeStringIsAcquisition(link.type)) {
                NYPLLOG(@"Ignoring featured feed without acquisition type.");
              } else {
                featuredURL = link.href;
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
          
          if(!featuredURL) {
            NYPLLOG(@"Creating lane without featured books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          id const featuredDataObject = dataDictionary[featuredURL];
          if([featuredDataObject isKindOfClass:[NSNull class]]) {
            NYPLLOG(@"Creating lane without unobtainable featured books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NSData *const featuredData = featuredDataObject;
          assert([featuredData isKindOfClass:[NSData class]]);
          
          SMXMLDocument *const document = [SMXMLDocument documentWithData:featuredData
                                                                    error:NULL];
          if(!document) {
            NYPLLOG(@"Creating lane without unparsable featured books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NYPLOPDSFeed *featuredAcquisitionFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];
          
          if(!featuredAcquisitionFeed) {
            NYPLLOG(@"Creating lane without invalid featured books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NSMutableArray *const books =
            [NSMutableArray arrayWithCapacity:featuredAcquisitionFeed.entries.count];
          
          for(NYPLOPDSEntry *const acquisitionEntry in featuredAcquisitionFeed.entries) {
            NYPLBook *const book = [NYPLBook bookWithEntry:acquisitionEntry];
            if(!book) {
              NYPLLOG(@"Failed to create book from entry.");
              continue;
            }
            [books addObject:book];
          }
          
          [lanes addObject:
           [[NYPLCatalogLane alloc]
            initWithBooks:books
            subsectionLink:subsectionLink
            title:navigationEntry.title]];
        }
        
        NYPLCatalogRoot *const root = [[NYPLCatalogRoot alloc] initWithLanes:lanes];
        assert(root);
        
        NYPLAsyncDispatch(^{handler(root);});
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
