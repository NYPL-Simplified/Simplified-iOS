#import "NYPLAsync.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogLane.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLXML.h"

#import "NYPLCatalogFacet.h"
#import "SimplyE-Swift.h"

#import "NYPLCatalogGroupedFeed.h"

@interface NYPLCatalogGroupedFeed ()

@property (nonatomic) NSArray *lanes;
@property (nonatomic) NSURL *openSearchURL;
@property (nonatomic) NSString *title;
@property (nonatomic) NSArray<NYPLCatalogFacet *> *entryPoints;


@end

@implementation NYPLCatalogGroupedFeed

- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *)feed
{
  if(feed.type != NYPLOPDSFeedTypeAcquisitionGrouped) {
    @throw NSInvalidArgumentException;
  }
  
  Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];

  NSURL *openSearchURL = nil;
  NSMutableArray *const entryPointFacets = [NSMutableArray array];
  
  for(NYPLOPDSLink *const link in feed.links) {

    if([link.rel isEqualToString:NYPLOPDSRelationFacet]) {
      for(NSString *const key in link.attributes) {
        if(NYPLOPDSAttributeKeyStringIsFacetGroupType(key)) {
          NYPLCatalogFacet *facet = [NYPLCatalogFacet catalogFacetWithLink:link];
          if (facet) {
            [entryPointFacets addObject:facet];
          } else {
            NYPLLOG(@"Entrypoint Facet could not be created.");
          }
          continue;
        }
      }
    }

    if([link.rel isEqualToString:NYPLOPDSRelationSearch] &&
       NYPLOPDSTypeStringIsOpenSearchDescription(link.type)) {
      openSearchURL = link.href;
      continue;
    }
    else if ([link.rel isEqualToString:NYPLOPDSEULALink]) {
      NSURL *href = link.href;
      [currentAccount.details setURL:href forLicense:URLTypeEula];
      continue;
    }
    else if ([link.rel isEqualToString:NYPLOPDSPrivacyPolicyLink]) {
      NSURL *href = link.href;
      [currentAccount.details setURL:href forLicense:URLTypePrivacyPolicy];
      continue;
    }
    else if ([link.rel isEqualToString:NYPLOPDSAcknowledgmentsLink]) {
      NSURL *href = link.href;
      [currentAccount.details setURL:href forLicense:URLTypeAcknowledgements];
      continue;
    }
    else if ([link.rel isEqualToString:NYPLOPDSContentLicenseLink]) {
      NSURL *href = link.href;
      [currentAccount.details setURL:href forLicense:URLTypeContentLicenses];
      continue;
    }
    else if ([link.rel isEqualToString:NYPLOPDSRelationAnnotations]) {
      NSURL *href = link.href;
      [currentAccount.details setURL:href forLicense:URLTypeAnnotations];
      continue;
    }
  }

  self.entryPoints = entryPointFacets;
  
  // This holds group titles in order, without duplicates.
  NSMutableArray *const groupTitles = [NSMutableArray array];
  
  NSMutableDictionary *const groupTitleToMutableBookArray = [NSMutableDictionary dictionary];
  NSMutableDictionary *const groupTitleToURLOrNull = [NSMutableDictionary dictionary];
  
  for(NYPLOPDSEntry *const entry in feed.entries) {
    if(!entry.groupAttributes) {
      NYPLLOG(@"Ignoring entry with missing group.");
      continue;
    }
    
    NSString *const groupTitle = entry.groupAttributes.title;
    
    NYPLBook *book = [NYPLBook bookWithEntry:entry];
    if(!book) {
      NYPLLOG_F(@"Failed to create book from entry: %@",entry.title);
      continue;
    }

    if(!book.defaultAcquisition) {
      // The application is not able to support this, so we ignore it.
      continue;
    }
    
    NYPLBook *updatedBook = [[NYPLBookRegistry sharedRegistry] updatedBookMetadata:book];
    if(updatedBook) {
      book = updatedBook;
    }
    
    NSMutableArray *const bookArray = groupTitleToMutableBookArray[groupTitle];
    if(bookArray) {
      // We previously found a book in this group, so we can just add one more.
      [bookArray addObject:book];
    } else {
      // This is the first book we've found in this group, so we need to do a few things.
      [groupTitles addObject:groupTitle];
      groupTitleToMutableBookArray[groupTitle] = [NSMutableArray arrayWithObject:book];
      groupTitleToURLOrNull[groupTitle] = NYPLNullFromNil(entry.groupAttributes.href);
    }
  }
  
  NSMutableArray *const lanes = [NSMutableArray array];
  
  for(NSString *const groupTitle in groupTitles) {
    [lanes addObject:[[NYPLCatalogLane alloc]
                      initWithBooks:groupTitleToMutableBookArray[groupTitle]
                      subsectionURL:NYPLNullToNil(groupTitleToURLOrNull[groupTitle])
                      title:groupTitle]];
  }
  
  return [self initWithLanes:lanes
               openSearchURL:openSearchURL
                       title:feed.title];
}

- (instancetype)initWithLanes:(NSArray *const)lanes
                openSearchURL:(NSURL *const)openSearchURL
                        title:(NSString *const)title
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
  self.openSearchURL = openSearchURL;
  self.title = title;
  
  return self;
}

@end
