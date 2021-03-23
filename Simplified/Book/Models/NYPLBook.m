#import "NSDate+NYPLDateAdditions.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nonatomic) NSArray<NYPLBookAuthor *> *bookAuthors;
@property (nonatomic) NSArray *categoryStrings;
@property (nonatomic) NSString *distributor;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic) NSURL *imageThumbnailURL;
@property (nonatomic) NSDate *published;
@property (nonatomic) NSString *publisher;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *summary;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;
@property (nonatomic) NSURL *annotationsURL;
@property (nonatomic) NSURL *analyticsURL;
@property (nonatomic) NSURL *alternateURL;
@property (nonatomic) NSURL *relatedWorksURL;
@property (nonatomic) NSURL *seriesURL;
@property (nonatomic) NSURL *revokeURL;
@property (nonatomic) NSURL *reportURL;

- (nonnull instancetype)initWithAcquisitions:(nonnull NSArray<NYPLOPDSAcquisition *> *)acquisitions
                                 bookAuthors:(nullable NSArray<NYPLBookAuthor *> *)authors
                             categoryStrings:(nullable NSArray *)categoryStrings
                                 distributor:(nullable NSString *)distributor
                                  identifier:(nonnull NSString *)identifier
                                    imageURL:(nullable NSURL *)imageURL
                           imageThumbnailURL:(nullable NSURL *)imageThumbnailURL
                                   published:(nullable NSDate *)published
                                   publisher:(nullable NSString *)publisher
                                    subtitle:(nullable NSString *)subtitle
                                     summary:(nullable NSString *)summary
                                       title:(nonnull NSString *)title
                                     updated:(nonnull NSDate *)updated
                              annotationsURL:(nullable NSURL *) annotationsURL
                                analyticsURL:(nullable NSURL *)analyticsURL
                                alternateURL:(nullable NSURL *)alternateURL
                             relatedWorksURL:(nullable NSURL *)relatedWorksURL
                                   seriesURL:(nullable NSURL *)seriesURL
                                   revokeURL:(nullable NSURL *)revokeURL
                                   reportURL:(nullable NSURL *)reportURL
NS_DESIGNATED_INITIALIZER;

@end

// NOTE: Be cautious of these values!
// Do NOT reuse them when declaring new keys.
static NSString *const DeprecatedAcquisitionKey = @"acquisition";
static NSString *const DeprecatedAvailableCopiesKey = @"available-copies";
static NSString *const DeprecatedAvailableUntilKey = @"available-until";
static NSString *const DeprecatedAvailabilityStatusKey = @"availability-status";
static NSString *const DeprecatedHoldsPositionKey = @"holds-position";
static NSString *const DeprecatedTotalCopiesKey = @"total-copies";

static NSString *const AcquisitionsKey = @"acquisitions";
static NSString *const AlternateURLKey = @"alternate";
static NSString *const AnalyticsURLKey = @"analytics";
static NSString *const AnnotationsURLKey = @"annotations";
static NSString *const AuthorLinksKey = @"author-links";
static NSString *const AuthorsKey = @"authors";
static NSString *const CategoriesKey = @"categories";
static NSString *const DistributorKey = @"distributor";
static NSString *const IdentifierKey = @"id";
static NSString *const ImageThumbnailURLKey = @"image-thumbnail";
static NSString *const ImageURLKey = @"image";
static NSString *const PublishedKey = @"published";
static NSString *const PublisherKey = @"publisher";
static NSString *const RelatedURLKey = @"related-works-url";
static NSString *const ReportURLKey = @"report-url";
static NSString *const RevokeURLKey = @"revoke-url";
static NSString *const SeriesLinkKey = @"series-link";
static NSString *const SubtitleKey = @"subtitle";
static NSString *const SummaryKey = @"summary";
static NSString *const TitleKey = @"title";
static NSString *const UpdatedKey = @"updated";

@implementation NYPLBook

+ (NSArray<NSString *> *)categoryStringsFromCategories:(NSArray<NYPLOPDSCategory *> *const)categories
{
  NSMutableArray<NSString *> *const categoryStrings = [NSMutableArray array];
  
  for(NYPLOPDSCategory *const category in categories) {
    if(!category.scheme
       || [category.scheme isEqual:[NSURL URLWithString:@"http://librarysimplified.org/terms/genres/Simplified/"]])
    {
      [categoryStrings addObject:(category.label ? category.label : category.term)];
    }
  }
  
  return [categoryStrings copy];
}

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *const)entry
{
  if(!entry) {
    NYPLLOG(@"Failed to create book from nil entry.");
    return nil;
  }
  
  NSURL *revoke, *image, *imageThumbnail, *report = nil;

  NSMutableArray<NYPLBookAuthor *> *authors = [[NSMutableArray alloc] init];
  for (int i = 0; i < (int)entry.authorStrings.count; i++) {
    if ((int)entry.authorLinks.count > i) {
      [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:entry.authorStrings[i]
                                                   relatedBooksURL:entry.authorLinks[i].href]];
    } else {
      [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:entry.authorStrings[i]
                                                   relatedBooksURL:nil]];
    }
  }

  for(NYPLOPDSLink *const link in entry.links) {
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionRevoke]) {
      revoke = link.href;
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
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionIssues]) {
      report = link.href;
      continue;
    }
  }
  
  return [[self alloc]
          initWithAcquisitions:entry.acquisitions
          bookAuthors:authors
          categoryStrings:[[self class] categoryStringsFromCategories:entry.categories]
          distributor:entry.providerName
          identifier:entry.identifier
          imageURL:image
          imageThumbnailURL:imageThumbnail
          published:entry.published
          publisher:entry.publisher
          subtitle:entry.alternativeHeadline
          summary:entry.summary
          title:entry.title
          updated:entry.updated
          annotationsURL:entry.annotations.href
          analyticsURL:entry.analytics
          alternateURL:entry.alternate.href
          relatedWorksURL:entry.relatedWorks.href
          seriesURL:entry.seriesLink.href
          revokeURL:revoke
          reportURL:report];
}

- (instancetype)bookWithMetadataFromBook:(NYPLBook *)book
{
  return [[NYPLBook alloc]
          initWithAcquisitions:self.acquisitions
          bookAuthors:book.bookAuthors
          categoryStrings:book.categoryStrings
          distributor:book.distributor
          identifier:self.identifier
          imageURL:book.imageURL
          imageThumbnailURL:book.imageThumbnailURL
          published:book.published
          publisher:book.publisher
          subtitle:book.subtitle
          summary:book.summary
          title:book.title
          updated:book.updated
          annotationsURL:book.annotationsURL
          analyticsURL:book.analyticsURL
          alternateURL:book.alternateURL
          relatedWorksURL:book.relatedWorksURL
          seriesURL:book.seriesURL
          revokeURL:self.revokeURL
          reportURL:self.reportURL];
}

- (instancetype)initWithAcquisitions:(NSArray<NYPLOPDSAcquisition *> *)acquisitions
                         bookAuthors:(NSArray<NYPLBookAuthor *> *)authors
                     categoryStrings:(NSArray *)categoryStrings
                         distributor:(NSString *)distributor
                          identifier:(NSString *)identifier
                            imageURL:(NSURL *)imageURL
                   imageThumbnailURL:(NSURL *)imageThumbnailURL
                           published:(NSDate *)published
                           publisher:(NSString *)publisher
                            subtitle:(NSString *)subtitle
                             summary:(NSString *)summary
                               title:(NSString *)title
                             updated:(NSDate *)updated
                      annotationsURL:(NSURL *)annotationsURL
                        analyticsURL:(NSURL *)analyticsURL
                        alternateURL:(NSURL *)alternateURL
                     relatedWorksURL:(NSURL *)relatedWorksURL
                           seriesURL:(NSURL *)seriesURL
                           revokeURL:(NSURL *)revokeURL
                           reportURL:(NSURL *)reportURL
{
  self = [super init];
  if(!self) return nil;
  
  if(!(acquisitions && identifier && title && updated)) {
    @throw NSInvalidArgumentException;
  }
  
  self.acquisitions = acquisitions;
  self.alternateURL = alternateURL;
  self.annotationsURL = annotationsURL;
  self.analyticsURL = analyticsURL;
  self.bookAuthors = authors;
  self.categoryStrings = categoryStrings;
  self.distributor = distributor;
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.published = published;
  self.publisher = publisher;
  self.relatedWorksURL = relatedWorksURL;
  self.seriesURL = seriesURL;
  self.subtitle = subtitle;
  self.summary = summary;
  self.title = title;
  self.updated = updated;
  self.revokeURL = revokeURL;
  self.reportURL = reportURL;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;

  // This is not present in older versions of serialized books.
  NSArray *const acquisitionsArray = dictionary[AcquisitionsKey];
  if (acquisitionsArray) {
    assert([acquisitionsArray isKindOfClass:[NSArray class]]);

    NSMutableArray<NYPLOPDSAcquisition *> *const mutableAcqusitions =
      [NSMutableArray arrayWithCapacity:acquisitionsArray.count];

    for (NSDictionary *const acquisitionDictionary in acquisitionsArray) {
      assert([acquisitionDictionary isKindOfClass:[NSDictionary class]]);

      NYPLOPDSAcquisition *const acquisition = [NYPLOPDSAcquisition acquisitionWithDictionary:acquisitionDictionary];
      assert(acquisition);

      [mutableAcqusitions addObject:acquisition];
    }

    self.acquisitions = [mutableAcqusitions copy];
  }

  // This is not present in older versions of serialized books.
  NSString *const revokeString = NYPLNullToNil(dictionary[RevokeURLKey]);
  self.revokeURL = revokeString ? [NSURL URLWithString:revokeString] : nil;

  // This is not present in older versions of serialized books.
  NSString *const reportString = NYPLNullToNil(dictionary[ReportURLKey]);
  self.reportURL = reportString ? [NSURL URLWithString:reportString] : nil;

  // If present, migrate old acquistion data to the new format.
  // This handles data originally serialized from an `NYPLBookAcquisition`.
  if (dictionary[DeprecatedAcquisitionKey]) {
    // Old-format acqusitions previously held all of these. As such, if we have an old-format
    // acquisition, none of these should have been successfully set above.
    assert(!self.acquisitions);
    assert(!self.revokeURL);
    assert(!self.reportURL);

    NSString *const revokeString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"revoke"]);
    self.revokeURL = revokeString ? [NSURL URLWithString:revokeString] : nil;

    NSString *const reportString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"report"]);
    self.reportURL = reportString ? [NSURL URLWithString:reportString] : nil;

    NSString *const availabilityStatus = NYPLNullToNil(dictionary[DeprecatedAvailabilityStatusKey]);

    NSString *const holdsPositionString = NYPLNullToNil(dictionary[DeprecatedHoldsPositionKey]);
    NSInteger const holdsPosition = holdsPositionString ? [holdsPositionString integerValue] : NSNotFound;

    NSString *const availableCopiesString = NYPLNullToNil(dictionary[DeprecatedAvailableCopiesKey]);
    NSInteger const availableCopies = availableCopiesString ? [availableCopiesString integerValue] : NSNotFound;

    NSString *const totalCopiesString = NYPLNullToNil(dictionary[DeprecatedTotalCopiesKey]);
    NSInteger const totalCopies = totalCopiesString ? [totalCopiesString integerValue] : NSNotFound;

    NSString *const untilString = NYPLNullToNil(dictionary[DeprecatedAvailableUntilKey]);
    NSDate *const until = untilString ? [NSDate dateWithRFC3339String:untilString] : nil;

    // This information is not available so we default to the until date.
    NSDate *const since = until;

    // Default to unlimited availability if we cannot deduce anything more specific.
    id<NYPLOPDSAcquisitionAvailability> availability = [[NYPLOPDSAcquisitionAvailabilityUnlimited alloc] init];

    if ([availabilityStatus isEqual:@"available"]) {
      if (availableCopies == NSNotFound) {
        // Use the default unlimited availability.
      } else {
        availability = [[NYPLOPDSAcquisitionAvailabilityLimited alloc]
                        initWithCopiesAvailable:availableCopies
                        copiesTotal:totalCopies
                        since:since
                        until:until];
      }
    } else if ([availabilityStatus isEqual:@"unavailable"]) {
      // Unfortunately, no record of copies already on hold is present. As such,
      // we default to `totalCopies` (which assumes one hold for every copy
      // available, i.e. demand doubling supply).
      availability = [[NYPLOPDSAcquisitionAvailabilityUnavailable alloc]
                      initWithCopiesHeld:totalCopies
                      copiesTotal:totalCopies];
    } else if ([availabilityStatus isEqual:@"reserved"]) {
      availability = [[NYPLOPDSAcquisitionAvailabilityReserved alloc]
                      initWithHoldPosition:holdsPosition
                      copiesTotal:totalCopies
                      since:since
                      until:until];
    } else if ([availabilityStatus isEqual:@"ready"]) {
      availability = [[NYPLOPDSAcquisitionAvailabilityReady alloc] initWithSince:since until:until];
    }

    NSMutableArray<NYPLOPDSAcquisition *> *const mutableAcquisitions = [NSMutableArray array];

    NSString *const applicationEPUBZIP = ContentTypeEpubZip;

    NSString *const genericString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"generic"]);
    NSURL *const genericURL = genericString ? [NSURL URLWithString:genericString] : nil;
    if (genericURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationGeneric
        type:applicationEPUBZIP
        hrefURL:genericURL
        indirectAcquisitions:@[]
        availability:availability]];
    }

    NSString *const borrowString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"borrow"]);
    NSURL *const borrowURL = borrowString ? [NSURL URLWithString:borrowString] : nil;
    if (borrowURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationBorrow
        type:applicationEPUBZIP
        hrefURL:borrowURL
        indirectAcquisitions:@[]
        availability:availability]];
    }

    NSString *const openAccessString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"open-access"]);
    NSURL *const openAccessURL = openAccessString ? [NSURL URLWithString:openAccessString] : nil;
    if (openAccessURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationOpenAccess
        type:applicationEPUBZIP
        hrefURL:openAccessURL
        indirectAcquisitions:@[]
        availability:availability]];
    }

    NSString *const sampleString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"sample"]);
    NSURL *const sampleURL = sampleString ? [NSURL URLWithString:sampleString] : nil;
    if (sampleURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationSample
        type:applicationEPUBZIP
        hrefURL:sampleURL
        indirectAcquisitions:@[]
        availability:availability]];
    }

    self.acquisitions = [mutableAcquisitions copy];
  }
  
  NSString *const alternate = NYPLNullToNil(dictionary[AlternateURLKey]);
  self.alternateURL = alternate ? [NSURL URLWithString:alternate] : nil;
  
  NSString *const analytics = NYPLNullToNil(dictionary[AnalyticsURLKey]);
  self.analyticsURL = analytics ? [NSURL URLWithString:analytics] : nil;
  
  NSString *const annotations = NYPLNullToNil(dictionary[AnnotationsURLKey]);
  self.annotationsURL = annotations ? [NSURL URLWithString:annotations] : nil;

  NSMutableArray<NYPLBookAuthor *> *authors = [[NSMutableArray alloc] init];
  NSArray *authorStrings = dictionary[AuthorsKey];
  NSArray *authorLinks = dictionary[AuthorLinksKey];

  if (authorStrings && authorLinks) {
    for (int i = 0; i < (int)authorStrings.count; i++) {
      if ((int)authorLinks.count > i) {
        NSURL *url = [NSURL URLWithString:authorLinks[i]];
        [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:authorStrings[i]
                                                      relatedBooksURL:url]];
      } else {
        [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:authorStrings[i]
                                                      relatedBooksURL:nil]];
      }
    }
  } else if (authorStrings) {
    for (int i = 0; i < (int)authorStrings.count; i++) {
      [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:authorStrings[i]
                                                    relatedBooksURL:nil]];
    }
  } else {
    self.bookAuthors = nil;
  }
  self.bookAuthors = authors;

  self.categoryStrings = dictionary[CategoriesKey];
  if(!self.categoryStrings) return nil;
  
  self.distributor = NYPLNullToNil(dictionary[DistributorKey]);
  
  self.identifier = dictionary[IdentifierKey];
  if(!self.identifier) return nil;
  
  NSString *const image = NYPLNullToNil(dictionary[ImageURLKey]);
  self.imageURL = image ? [NSURL URLWithString:image] : nil;
  
  NSString *const imageThumbnail = NYPLNullToNil(dictionary[ImageThumbnailURLKey]);
  self.imageThumbnailURL = imageThumbnail ? [NSURL URLWithString:imageThumbnail] : nil;
  
  NSString *const dateString = NYPLNullToNil(dictionary[PublishedKey]);
  self.published = dateString ? [NSDate dateWithRFC3339String:dateString] : nil;
  
  self.publisher = NYPLNullToNil(dictionary[PublisherKey]);
  
  NSString *const relatedWorksString = NYPLNullToNil(dictionary[RelatedURLKey]);
  self.relatedWorksURL = relatedWorksString ? [NSURL URLWithString:relatedWorksString] : nil;
  
  NSString *const seriesString = NYPLNullToNil(dictionary[SeriesLinkKey]);
  self.seriesURL = seriesString ? [NSURL URLWithString:seriesString] : nil;
  
  self.subtitle = NYPLNullToNil(dictionary[SubtitleKey]);
  
  self.summary = NYPLNullToNil(dictionary[SummaryKey]);
  
  self.title = dictionary[TitleKey];
  if(!self.title) return nil;
  
  self.updated = [NSDate dateWithRFC3339String:dictionary[UpdatedKey]];
  if(!self.updated) return nil;
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableArray *const mutableAcquisitionDictionaryArray = [NSMutableArray arrayWithCapacity:self.acquisitions.count];

  for (NYPLOPDSAcquisition *const acquisition in self.acquisitions) {
    [mutableAcquisitionDictionaryArray addObject:[acquisition dictionaryRepresentation]];
  }

  return @{AcquisitionsKey:[mutableAcquisitionDictionaryArray copy],
           AlternateURLKey: NYPLNullFromNil([self.alternateURL absoluteString]),
           AnnotationsURLKey: NYPLNullFromNil([self.annotationsURL absoluteString]),
           AnalyticsURLKey: NYPLNullFromNil([self.analyticsURL absoluteString]),
           AuthorLinksKey: [self authorLinkArray],
           AuthorsKey: [self authorNameArray],
           CategoriesKey: self.categoryStrings,
           DistributorKey: NYPLNullFromNil(self.distributor),
           IdentifierKey: self.identifier,
           ImageURLKey: NYPLNullFromNil([self.imageURL absoluteString]),
           ImageThumbnailURLKey: NYPLNullFromNil([self.imageThumbnailURL absoluteString]),
           PublishedKey: NYPLNullFromNil([self.published RFC3339String]),
           PublisherKey: NYPLNullFromNil(self.publisher),
           RelatedURLKey: NYPLNullFromNil([self.relatedWorksURL absoluteString]),
           ReportURLKey: NYPLNullFromNil([self.reportURL absoluteString]),
           RevokeURLKey: NYPLNullFromNil([self.revokeURL absoluteString]),
           SeriesLinkKey: NYPLNullFromNil([self.seriesURL absoluteString]),
           SubtitleKey: NYPLNullFromNil(self.subtitle),
           SummaryKey: NYPLNullFromNil(self.summary),
           TitleKey: self.title,
           UpdatedKey: [self.updated RFC3339String]
          };
}

- (NSArray *)authorNameArray {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (NYPLBookAuthor *auth in self.bookAuthors) {
    if (auth.name) {
      [array addObject:auth.name];
    }
  }
  return array;
}

- (NSArray *)authorLinkArray {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (NYPLBookAuthor *auth in self.bookAuthors) {
    if (auth.relatedBooksURL.absoluteString) {
      [array addObject:auth.relatedBooksURL.absoluteString];
    }
  }
  return array;
}

- (NSString *)authors
{
  NSMutableArray *authorsArray = [[NSMutableArray alloc] init];
  for (NYPLBookAuthor *author in self.bookAuthors) {
    [authorsArray addObject:author.name];
  }
  return [authorsArray componentsJoinedByString:@"; "];
}

- (NSString *)categories
{
  return [self.categoryStrings componentsJoinedByString:@"; "];
}

- (NYPLOPDSAcquisition *)defaultAcquisition
{
  if (self.acquisitions.count == 0) {
    NYPLLOG(@"ERROR: No acquisitions found when computing a default. This is an OPDS violation.");
    return nil;
  }

  for (NYPLOPDSAcquisition *const acquisition in self.acquisitions) {
    NSArray *const paths = [NYPLBookAcquisitionPath
                            supportedAcquisitionPathsForAllowedTypes:[NYPLBookAcquisitionPath supportedTypes]
                            allowedRelations:NYPLOPDSAcquisitionRelationSetAll
                            acquisitions:@[acquisition]];

    if (paths.count >= 1) {
      return acquisition;
    }
  }

  return nil;
}

- (NYPLOPDSAcquisition *)defaultAcquisitionIfBorrow
{
  NYPLOPDSAcquisition *const acquisition = [self defaultAcquisition];

  return acquisition.relation == NYPLOPDSAcquisitionRelationBorrow ? acquisition : nil;
}

- (NYPLOPDSAcquisition *)defaultAcquisitionIfOpenAccess
{
  NYPLOPDSAcquisition *const acquisition = [self defaultAcquisition];

  return acquisition.relation == NYPLOPDSAcquisitionRelationOpenAccess ? acquisition : nil;
}

- (NYPLBookContentType)defaultBookContentType
{
  NYPLOPDSAcquisition *acquisition = [self defaultAcquisition];
  if (!acquisition) {
    // Avoid crashing by attempting to put nil in an array below
    return NYPLBookContentTypeUnsupported;
  }
  
  NSArray<NYPLBookAcquisitionPath *> *const paths =
  [NYPLBookAcquisitionPath
   supportedAcquisitionPathsForAllowedTypes:[NYPLBookAcquisitionPath supportedTypes]
   allowedRelations:NYPLOPDSAcquisitionRelationSetAll
   acquisitions:@[acquisition]];

  NYPLBookContentType defaultType = NYPLBookContentTypeUnsupported;
  for (NYPLBookAcquisitionPath *const path in paths) {
    NSString *finalTypeString = path.types.lastObject;
    NYPLBookContentType const contentType = NYPLBookContentTypeFromMIMEType(finalTypeString);
    
    // Prefer EPUB, because we have the best support for them
    if (contentType == NYPLBookContentTypeEPUB) {
      defaultType = contentType;
      break;
    }
    
    // Assign the first supported type, to fall back on if EPUB isn't an option
    if (defaultType == NYPLBookContentTypeUnsupported) {
      defaultType = contentType;
    }
  }
  
  return defaultType;
}

@end
