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
@property (nonatomic) BOOL noSupportedBooksInLastFetch;
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

+ (void)withURL:(NSURL *)URL
handler:(void (^)(NYPLCatalogUngroupedFeed *category))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }
  
  [NYPLOPDSFeed
   withURL:URL
   shouldResetCache:NO
   completionHandler:^(NYPLOPDSFeed *const ungroupedFeed, __unused NSDictionary *error) {
     if(!ungroupedFeed) {
       handler(nil);
       return;
     }
     
     if(ungroupedFeed.type != NYPLOPDSFeedTypeAcquisitionUngrouped) {
       NYPLLOG(@"Ignoring feed of invalid type.");
       handler(nil);
       return;
     }
     
    NYPLCatalogUngroupedFeed *feed = [[self alloc] initWithOPDSFeed:ungroupedFeed];
    
    if (feed.noSupportedBooksInLastFetch) {
      [feed fetchNextPageWithCompletionHandler:handler];
    } else {
      handler(feed);
    }
   }];
}

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
  self.noSupportedBooksInLastFetch = (self.books.count == 0) && (feed.entries.count > 0);

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
  
  if(self.books.count - bookIndex > preloadThreshold) {
    return;
  }
  
  [self fetchNextPageWithCompletionHandler:nil];
}

// Continues to recursively fetch results from `nextURL` if all the books from last fetch are not supported.
// @param completion handler, executed when booksFromLastFetchNotSupported, no next url or fetch failed
- (void)fetchNextPageWithCompletionHandler:(nullable void (^)(NYPLCatalogUngroupedFeed *category))handler
{
  if(self.currentlyFetchingNextURL) {
    return;
  }
  
  if(!self.nextURL) {
    if (handler) {
      handler(self);
    }
    return;
  }
  
  self.currentlyFetchingNextURL = YES;
  
  NSUInteger const location = self.books.count;
  
  [NYPLCatalogUngroupedFeed
   withURL:self.nextURL
   handler:^(NYPLCatalogUngroupedFeed *const ungroupedFeed) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       if(!ungroupedFeed) {
         NYPLLOG(@"Failed to fetch next page.");
         self.currentlyFetchingNextURL = NO;
         if(handler) {
           handler(self);
         }
         return;
       }
       
       [self.books addObjectsFromArray:ungroupedFeed.books];
       self.nextURL = ungroupedFeed.nextURL;
       self.currentlyFetchingNextURL = NO;
       
       if (!self.noSupportedBooksInLastFetch) {
         // Continues the recursive loop originated from prepareForBookIndex
         [self prepareForBookIndex:self.greatestPreparationIndex];
       } else if (handler) {
         // Exit the recursive loop when booksFromLastFetchNotSupported
         handler(self);
         return;
       }
       
       NSRange const range = {.location = location, .length = ungroupedFeed.books.count};
       
       [self.delegate catalogUngroupedFeed:self
                               didAddBooks:ungroupedFeed.books
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
