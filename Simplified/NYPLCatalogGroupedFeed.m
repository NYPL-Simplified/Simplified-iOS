#import "NYPLAsync.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogLane.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLSession.h"
#import "NYPLXML.h"

#import "NYPLCatalogGroupedFeed.h"

@interface NYPLCatalogGroupedFeed ()

@property (nonatomic) NSArray *lanes;
@property (nonatomic) NSString *searchTemplate;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogGroupedFeed

- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *)feed
{
  if(feed.type != NYPLOPDSFeedTypeAcquisitionGrouped) {
    @throw NSInvalidArgumentException;
  }
  
  NSURL *openSearchURL = nil;
  
  for(NYPLOPDSLink *const link in feed.links) {
    if([link.rel isEqualToString:NYPLOPDSRelationSearch] &&
       NYPLOPDSTypeStringIsOpenSearchDescription(link.type)) {
      openSearchURL = link.href;
      break;
    }
  }
  
  
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
    
    NYPLBook *const book = [NYPLBook bookWithEntry:entry];
    if(!book) {
      NYPLLOG(@"Failed to create book from entry.");
      continue;
    }
    
    // We sync the latest metadata with the registry just in case it has changed.
    [[NYPLBookRegistry sharedRegistry] updateBook:book];
    
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
  
  // FIXME: |searchTemplate:| is passed nil because this method needs to return immediately and
  // getting the template requires network access. What we should do instead is just store the
  // URL of the open search document and let the view controller fetch it later.
  return [self initWithLanes:lanes
              searchTemplate:nil
                       title:feed.title];
}

- (instancetype)initWithLanes:(NSArray *const)lanes
               searchTemplate:(NSString *const)searchTemplate
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
  self.searchTemplate = searchTemplate;
  self.title = title;
  
  return self;
}

@end
