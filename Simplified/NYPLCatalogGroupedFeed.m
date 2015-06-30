#import "NYPLAsync.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogSubsectionLink.h"
#import "NYPLOPDS.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLSession.h"
#import "NYPLXML.h"

#import "NYPLCatalogGroupedFeed.h"

@interface NYPLCatalogGroupedFeed ()

@property (nonatomic) NSArray *lanes;
@property (nonatomic) NSString *searchTemplate;

@end

@implementation NYPLCatalogGroupedFeed

+ (void)withURL:(NSURL *const)URL
        handler:(void (^)(NYPLCatalogGroupedFeed *root))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }
  
  [NYPLOPDSFeed
   withURL:URL
   completionHandler:^(NYPLOPDSFeed *const navigationFeed) {
     if(!navigationFeed) {
       NYPLLOG(@"Failed to retrieve main navigation feed.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NSURL *openSearchURL = nil;
     
     for(NYPLOPDSLink *const link in navigationFeed.links) {
       if([link.rel isEqualToString:NYPLOPDSRelationSearch] &&
          NYPLOPDSTypeStringIsOpenSearchDescription(link.type)) {
         openSearchURL = link.href;
       }
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
      withURLs:featuredURLs handler:^(NSDictionary *const URLsToDataOrNull) {
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
            } else {
              // TODO: We assume the last acquisition or navigation feed is the main feed for the
              // lane. Is there a relation we should be using to do a better job of this? We
              // previously used 'subsection', but it's unclear to me if that is appropriate for
              // acquisition feeds.
              if(NYPLOPDSTypeStringIsAcquisition(link.type)) {
                subsectionLink = [[NYPLCatalogSubsectionLink alloc]
                                  initWithType:NYPLCatalogSubsectionLinkTypeAcquisition
                                  URL:link.href];
              } else if(NYPLOPDSTypeStringIsNavigation(link.type)) {
                subsectionLink = [[NYPLCatalogSubsectionLink alloc]
                                  initWithType:NYPLCatalogSubsectionLinkTypeNavigation
                                  URL:link.href];
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
          
          id const featuredDataObject = URLsToDataOrNull[featuredURL];
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
          
          NYPLXML *const feedXML = [NYPLXML XMLWithData:featuredData];
          
          if(!feedXML) {
            NYPLLOG(@"Creating lane without unparsable featured books.");
            [lanes addObject:
             [[NYPLCatalogLane alloc]
              initWithBooks:@[]
              subsectionLink:subsectionLink
              title:navigationEntry.title]];
            continue;
          }
          
          NYPLOPDSFeed *featuredAcquisitionFeed = [[NYPLOPDSFeed alloc] initWithXML:feedXML];
          
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
            [[NYPLBookRegistry sharedRegistry] updateBook:book];
            [books addObject:book];
          }
          
          [lanes addObject:
           [[NYPLCatalogLane alloc]
            initWithBooks:books
            subsectionLink:subsectionLink
            title:navigationEntry.title]];
        }
        
        if(openSearchURL) {
          [NYPLOpenSearchDescription
           withURL:openSearchURL
           completionHandler:^(NYPLOpenSearchDescription *const description) {
             if(!description) {
               NYPLLOG(@"Failed to retrieve OpenSearch description document.");
             }
             NYPLAsyncDispatch(^{handler([[NYPLCatalogGroupedFeed alloc]
                                          initWithLanes:lanes
                                          searchTemplate:description.OPDSURLTemplate]);});
           }];
        } else {
          NYPLAsyncDispatch(^{handler([[NYPLCatalogGroupedFeed alloc]
                                       initWithLanes:lanes
                                       searchTemplate:nil]);});
        }
      }];
   }];
}

- (instancetype)initWithLanes:(NSArray *const)lanes
               searchTemplate:(NSString *const)searchTemplate
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
  self.searchTemplate = searchTemplate;
  
  return self;
}

@end
