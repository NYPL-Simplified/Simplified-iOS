#import "NYPLAsync.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFacet.h"
#import "NYPLCatalogFacetGroup.h"
#import "NYPLOPDS.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

#import "NYPLCatalogUngroupedFeed.h"

@interface NYPLCatalogUngroupedFeed ()

@property (nonatomic) BOOL currentlyFetchingNextURL;
@property (nonatomic) NSMutableArray *books;
@property (nonatomic) NSArray *facetGroups;
@property (nonatomic) NSUInteger greatestPreparationIndex;
@property (nonatomic) NSURL *nextURL;
@property (nonatomic) NSURL *openSearchURL;
@property (nonatomic) NSArray<NYPLCatalogFacet *> *entryPoints;

@end

// If fewer than this many books are currently available when |prepareForBookIndex:| is called, an
// attempt to fetch more books will be made.
static NSUInteger const preloadThreshold = 100;

@implementation NYPLCatalogUngroupedFeed

- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *const)feed
{
  self = [super init];
  if(!self) return nil;
  
  if(feed.type != NYPLOPDSFeedTypeAcquisitionUngrouped) {
    @throw NSInvalidArgumentException;
  }
  
  self.books = [NSMutableArray array];
  
  for(NYPLOPDSEntry *const entry in feed.entries) {
    NYPLBook *book = [NYPLBook bookWithEntry:entry];
    if(!book) {
      NYPLLOG(@"Failed to create book from entry.");
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
    [self.books addObject:book];
  }

  NSMutableArray *const entryPointFacets = [NSMutableArray array];
  NSMutableArray *const facetGroupNames = [NSMutableArray array];
  NSMutableDictionary *const facetGroupNamesToMutableFacetArrays =
    [NSMutableDictionary dictionary];
  
  for(NYPLOPDSLink *const link in feed.links) {
    if([link.rel isEqualToString:NYPLOPDSRelationFacet]) {

      NSString *groupName = nil;
      NYPLCatalogFacet *facet = nil;
      for(NSString *const key in link.attributes) {
        if(NYPLOPDSAttributeKeyStringIsFacetGroupType(key)) {
          facet = [NYPLCatalogFacet catalogFacetWithLink:link];
          if (facet) {
            [entryPointFacets addObject:facet];
          } else {
            NYPLLOG(@"Entrypoint Facet could not be created.");
          }
          break;
        } else if(NYPLOPDSAttributeKeyStringIsFacetGroup(key)) {
          groupName = link.attributes[key];
          continue;
        }
      }

      if (facet) {
        continue;
      }
      if(!groupName) {
        NYPLLOG(@"Ignoring facet without group due to UI limitations.");
        continue;
      }

      facet = [NYPLCatalogFacet catalogFacetWithLink:link];
      if(!facet) {
        NYPLLOG(@"Ignoring invalid facet link.");
        continue;
      }

      if(![facetGroupNames containsObject:groupName]) {
        [facetGroupNames addObject:groupName];
        facetGroupNamesToMutableFacetArrays[groupName] = [NSMutableArray arrayWithCapacity:2];
      }
      [facetGroupNamesToMutableFacetArrays[groupName] addObject:facet];
      continue;
    }

    if([link.rel isEqualToString:NYPLOPDSRelationPaginationNext]) {
      self.nextURL = link.href;
      continue;
    }
    
    if([link.rel isEqualToString:NYPLOPDSRelationSearch] &&
       NYPLOPDSTypeStringIsOpenSearchDescription(link.type)) {
      self.openSearchURL = link.href;
      continue;
    }
  }
  
  // Care is taken to preserve facet and facet group order from the original feed.
  NSMutableArray *const facetGroups = [NSMutableArray arrayWithCapacity:facetGroupNames.count];
  for(NSString *const facetGroupName in facetGroupNames) {
    [facetGroups addObject:[[NYPLCatalogFacetGroup alloc]
                            initWithFacets:facetGroupNamesToMutableFacetArrays[facetGroupName]
                            name:facetGroupName]];
  }
  
  self.facetGroups = facetGroups;
  self.entryPoints = entryPointFacets;
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(refreshBooks)
   name:NSNotification.NYPLBookRegistryDidChange
   object:nil];

  return self;
}

- (void)prepareForBookIndex:(NSUInteger)bookIndex
{
  if(bookIndex >= self.books.count) {
    @throw NSInvalidArgumentException;
  }
  
  if(bookIndex < self.greatestPreparationIndex) {
    return;
  }
  
  self.greatestPreparationIndex = bookIndex;
  
  if(self.currentlyFetchingNextURL) return;
  
  if(!self.nextURL) return;
  
  if(self.books.count - bookIndex > preloadThreshold) {
    return;
  }
  
  self.currentlyFetchingNextURL = YES;
  
  NSUInteger const location = self.books.count;
  
  [NYPLOPDSFeedFetcher fetchCatalogUngroupedFeedWithUrl:self.nextURL
                                        networkExecutor:[NYPLNetworkExecutor shared]
                                             retryCount:0
                                             completion:^(NYPLCatalogUngroupedFeed * _Nullable feed) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      self.currentlyFetchingNextURL = NO;
      
      if(!feed) {
        NYPLLOG(@"Failed to fetch next page.");
        return;
      }
      
      [self.books addObjectsFromArray:feed.books];
      self.nextURL = feed.nextURL;
      
      [self prepareForBookIndex:self.greatestPreparationIndex];
      
      NSRange const range = {.location = location, .length = feed.books.count};
      
      [self.delegate catalogUngroupedFeed:self
                              didAddBooks:feed.books
                                    range:range];
    }];
  }];
}

- (void)refreshBooks
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    NSMutableArray *const refreshedBooks = [NSMutableArray arrayWithCapacity:self.books.count];
    
    for(NYPLBook *const book in self.books) {
      NYPLBook *const refreshedBook = [[NYPLBookRegistry sharedRegistry]
                                       bookForIdentifier:book.identifier];
      if(refreshedBook) {
        [refreshedBooks addObject:refreshedBook];
      } else {
        [refreshedBooks addObject:book];
      }
    }
    
    self.books = refreshedBooks;
    
    [self.delegate catalogUngroupedFeed:self didUpdateBooks:self.books];
  }];
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
