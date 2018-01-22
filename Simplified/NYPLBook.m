#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSAcquisition.h"
#import "NYPLOPDSIndirectAcquisition.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nonatomic) NSArray<NYPLBookAuthor *> *bookAuthors;
@property (nonatomic) NYPLBookAvailabilityStatus availabilityStatus;
@property (nonatomic) NSInteger availableCopies;
@property (nonatomic) NSDate *availableUntil;
@property (nonatomic) NSInteger totalCopies;
@property (nonatomic) NSInteger holdsPosition;
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
@property (nonatomic) NSDictionary *licensor;
@property (nonatomic) NSURL *revokeURL;
@property (nonatomic) NSURL *reportURL;

@end

static NSString *const AcquisitionsKey = @"acquisitions";
static NSString *const AlternateURLKey = @"alternate";
static NSString *const AnalyticsURLKey = @"analytics";
static NSString *const AnnotationsURLKey = @"annotations";
static NSString *const AuthorLinksKey = @"author-links";
static NSString *const AuthorsKey = @"authors";
static NSString *const AvailabilityStatusKey = @"availability-status";
static NSString *const AvailableCopiesKey = @"available-copies";
static NSString *const AvailableUntilKey = @"available-until";
static NSString *const CategoriesKey = @"categories";
static NSString *const DeprecatedAcquisitionKey = @"acquisition";
static NSString *const DistributorKey = @"distributor";
static NSString *const HoldsPositionKey = @"holds-position";
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
static NSString *const TotalCopiesKey = @"total-copies";
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
  
  NSURL *borrow, *generic, *openAccess, *revoke, *sample, *image, *imageThumbnail, *annotations, *report = nil;
  NSDictionary *licensor = nil;
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

  NYPLBookAvailabilityStatus availabilityStatus = NYPLBookAvailabilityStatusUnknown;
  NSInteger availableCopies = 0;
  NSInteger totalCopies = 0;
  NSInteger holdsPosition = 0;
  NSDate *availableUntil = nil;
  NSArray *borrowFormats = @[];

  for(NYPLOPDSLink *const link in entry.links) {
    if (link.licensor) {
      licensor = link.licensor;
    }

    if(link.availabilityStatus) {
      if([link.availabilityStatus isEqualToString:@"available"]) {
        availabilityStatus = NYPLBookAvailabilityStatusAvailable;
      } else if([link.availabilityStatus isEqualToString:@"unavailable"]) {
        availabilityStatus = NYPLBookAvailabilityStatusUnavailable;
      } else if([link.availabilityStatus isEqualToString:@"ready"]) {
        availabilityStatus = NYPLBookAvailabilityStatusReady;
      } else if([link.availabilityStatus isEqualToString:@"reserved"]) {
        availabilityStatus = NYPLBookAvailabilityStatusReserved;
      }
    }
    if(link.availableCopies > availableCopies) {
      availableCopies = link.availableCopies;
    }
    if(link.availableUntil) {
      availableUntil = link.availableUntil;
    }
    if(link.totalCopies > totalCopies) {
      totalCopies = link.totalCopies;
    }
    if(link.holdsPosition > holdsPosition) {
      holdsPosition = link.holdsPosition;
    }
    
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisition]) {
      generic = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionBorrow]) {
      borrow = link.href;
      borrowFormats = link.acquisitionFormats;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionOpenAccess]) {
      
      for(NSString *const acqusitionFormat in link.acquisitionFormats) {
        if([acqusitionFormat containsString:@"application/epub+zip"]) {
          openAccess = link.href;
          continue;
        }
      }
     
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionRevoke]) {
      revoke = link.href;
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
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionIssues]) {
      report = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAnnotations]) {
      annotations = link.href;
      continue;
    }
  }
  
  if(availabilityStatus == NYPLBookAvailabilityStatusUnknown) {
    if(openAccess || availableCopies > 0) {
      availabilityStatus = NYPLBookAvailabilityStatusAvailable;
    } else {
      availabilityStatus = NYPLBookAvailabilityStatusUnavailable;
    }
  }
  
  return [[self alloc]
          initWithAcquisitions:entry.acquisitions
          bookAuthors:authors
          availabilityStatus:availabilityStatus
          availableCopies:availableCopies
          availableUntil:availableUntil
          totalCopies:totalCopies
          holdsPosition:holdsPosition
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
          licensor:licensor
          revokeURL:revoke
          reportURL:report];
}

- (instancetype)bookWithMetadataFromBook:(NYPLBook *)book
{
  return [[NYPLBook alloc]
          initWithAcquisitions:self.acquisitions
          bookAuthors:book.bookAuthors
          availabilityStatus:self.availabilityStatus
          availableCopies:self.availableCopies
          availableUntil:self.availableUntil
          totalCopies:self.totalCopies
          holdsPosition:self.holdsPosition
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
          licensor:book.licensor
          revokeURL:self.revokeURL
          reportURL:self.reportURL];
}

- (instancetype)initWithAcquisitions:(NSArray<NYPLOPDSAcquisition *> *)acquisitions
                         bookAuthors:(NSArray<NYPLBookAuthor *> *)authors
                  availabilityStatus:(NYPLBookAvailabilityStatus)availabilityStatus
                     availableCopies:(NSInteger)availableCopies
                      availableUntil:(NSDate *)availableUntil
                         totalCopies:(NSInteger)totalCopies
                       holdsPosition:(NSInteger)holdsPosition
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
                            licensor:(NSDictionary *)licensor
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
  self.availabilityStatus = availabilityStatus;
  self.availableCopies = availableCopies;
  self.availableUntil = availableUntil;
  self.totalCopies = totalCopies;
  self.holdsPosition = holdsPosition;
  self.categoryStrings = categoryStrings;
  self.distributor = distributor;
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.licensor = licensor;
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

    NSMutableArray<NYPLOPDSAcquisition *> *const mutableAcquisitions = [NSMutableArray array];

    NSString *const applicationEPUBZIP = @"application/epub+zip";

    NSString *const genericString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"generic"]);
    NSURL *const genericURL = genericString ? [NSURL URLWithString:genericString] : nil;
    if (genericURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationGeneric
        type:applicationEPUBZIP
        hrefURL:genericURL
        indirectAcquisitions:@[]]];
    }

    NSString *const borrowString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"borrow"]);
    NSURL *const borrowURL = borrowString ? [NSURL URLWithString:borrowString] : nil;
    if (borrowURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationBorrow
        type:applicationEPUBZIP
        hrefURL:borrowURL
        indirectAcquisitions:@[]]];
    }

    NSString *const openAccessString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"open-access"]);
    NSURL *const openAccessURL = openAccessString ? [NSURL URLWithString:openAccessString] : nil;
    if (openAccessURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationOpenAccess
        type:applicationEPUBZIP
        hrefURL:openAccessURL
        indirectAcquisitions:@[]]];
    }

    NSString *const sampleString = NYPLNullToNil(dictionary[DeprecatedAcquisitionKey][@"sample"]);
    NSURL *const sampleURL = sampleString ? [NSURL URLWithString:sampleString] : nil;
    if (sampleURL) {
      [mutableAcquisitions addObject:
       [NYPLOPDSAcquisition
        acquisitionWithRelation:NYPLOPDSAcquisitionRelationSample
        type:applicationEPUBZIP
        hrefURL:sampleURL
        indirectAcquisitions:@[]]];
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
        if (url) {
          [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:authorStrings[i]
                                                        relatedBooksURL:url]];
        } else {
          [authors addObject:[[NYPLBookAuthor alloc] initWithAuthorName:authorStrings[i]
                                                        relatedBooksURL:nil]];
        }
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
  
  self.availabilityStatus = [dictionary[AvailabilityStatusKey] integerValue];
  self.availableCopies = [dictionary[AvailableCopiesKey] integerValue];
  self.totalCopies = [dictionary[TotalCopiesKey] integerValue];
  self.holdsPosition = [dictionary[HoldsPositionKey] integerValue];
  
  NSString *const availableUntilString = NYPLNullToNil(dictionary[AvailableUntilKey]);
  self.availableUntil = NYPLNullToNil(availableUntilString ? [NSDate dateWithRFC3339String:availableUntilString] : nil);
  
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
           AvailabilityStatusKey: @(self.availabilityStatus),
           AvailableCopiesKey: @(self.availableCopies),
           AvailableUntilKey: NYPLNullFromNil([self.availableUntil RFC3339String]),
           CategoriesKey: self.categoryStrings,
           DistributorKey: NYPLNullFromNil(self.distributor),
           IdentifierKey: self.identifier,
           ImageURLKey: NYPLNullFromNil([self.imageURL absoluteString]),
           ImageThumbnailURLKey: NYPLNullFromNil([self.imageThumbnailURL absoluteString]),
           PublishedKey: NYPLNullFromNil([self.published RFC3339String]),
           PublisherKey: NYPLNullFromNil(self.publisher),
           RelatedURLKey: NYPLNullFromNil([self.relatedWorksURL absoluteString]),
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
  for (NYPLOPDSAcquisition *const acquisition in self.acquisitions) {
    if ([acquisition.type isEqualToString:@"application/epub+zip"]) {
      return acquisition;
    }

    if (acquisition.indirectAcquisitions.count >= 1
        && [acquisition.indirectAcquisitions.lastObject.type isEqualToString:@"application/epub+zip"])
    {
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

@end
