#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBookAcquisition.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "NYPLConfiguration.h"

#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NYPLBookAcquisition *acquisition;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NYPLBookAvailabilityStatus availabilityStatus;
@property (nonatomic) NSInteger availableCopies;
@property (nonatomic) NSDate *availableUntil;
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

@property (nonatomic) NSDictionary *licensor;

@end

static NSString *const AcquisitionKey = @"acquisition";
static NSString *const AuthorsKey = @"authors";
static NSString *const AvailabilityStatusKey = @"availability-status";
static NSString *const AvailableCopiesKey = @"available-copies";
static NSString *const AvailableUntilKey = @"available-until";
static NSString *const CategoriesKey = @"categories";
static NSString *const DistributorKey = @"distributor";
static NSString *const IdentifierKey = @"id";
static NSString *const ImageURLKey = @"image";
static NSString *const ImageThumbnailURLKey = @"image-thumbnail";
static NSString *const PublishedKey = @"published";
static NSString *const PublisherKey = @"publisher";
static NSString *const SubtitleKey = @"subtitle";
static NSString *const SummaryKey = @"summary";
static NSString *const TitleKey = @"title";
static NSString *const UpdatedKey = @"updated";
static NSString *const AnnotationsURLKey = @"annotations";
static NSString *const AnalyticsURLKey = @"analytics";
static NSString *const AlternateURLKey = @"alternate";

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
  
  NYPLBookAvailabilityStatus availabilityStatus = NYPLBookAvailabilityStatusUnknown;
  NSInteger availableCopies = 0;
  NSDate *availableUntil = nil;
  NSArray *borrowFormats = @[];
  BOOL isEPUBAvailable = NO;
  for(NYPLOPDSLink *const link in entry.links) {
    for(NSString *const acqusitionFormat in link.acquisitionFormats) {
      if([acqusitionFormat containsString:@"application/epub+zip"]) {
        isEPUBAvailable = YES;
      }
    }
    if (link.licensor != nil)
    {
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
  
  // FIXME: This is not really the right place to do this and it doesn't handle
  // indirect acquisitions properly. NYPLOPDS* classes need to be reworked before
  // this can be handled in the correct way. The download center also needs to be
  // audited to ensure it always gets an EPUB if one is available.
  if(!isEPUBAvailable) {
    return nil;
  }
  
  if(availabilityStatus == NYPLBookAvailabilityStatusUnknown) {
    if(openAccess || availableCopies > 0) {
      availabilityStatus = NYPLBookAvailabilityStatusAvailable;
    } else {
      availabilityStatus = NYPLBookAvailabilityStatusUnavailable;
    }
  }
  
  return [[self alloc]
          initWithAcquisition:[[NYPLBookAcquisition alloc]
                               initWithBorrow:borrow
                               generic:generic
                               openAccess:openAccess
                               revoke:revoke
                               sample:sample
                               report:report]
          authorStrings:entry.authorStrings
          availabilityStatus: availabilityStatus
          availableCopies:availableCopies
          availableUntil:availableUntil
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
          licensor:licensor];
}

- (instancetype)bookWithMetadataFromBook:(NYPLBook *)book
{
  return [[NYPLBook alloc]
          initWithAcquisition:self.acquisition
          authorStrings:book.authorStrings
          availabilityStatus:self.availabilityStatus
          availableCopies:self.availableCopies
          availableUntil:self.availableUntil
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
          licensor:book.licensor];
}

- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                 availabilityStatus:(NYPLBookAvailabilityStatus)availabilityStatus
                    availableCopies:(NSInteger)availableCopies
                     availableUntil:(NSDate *)availableUntil
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
                           licensor:(NSDictionary *)licensor
{
  self = [super init];
  if(!self) return nil;
  
  if(!(acquisition && authorStrings && identifier && title && updated)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in authorStrings) {
    if(![object isKindOfClass:[NSString class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.acquisition = acquisition;
  self.authorStrings = authorStrings;
  self.availabilityStatus = availabilityStatus;
  self.availableCopies = availableCopies;
  self.availableUntil = availableUntil;
  self.categoryStrings = categoryStrings;
  self.distributor = distributor;
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.published = published;
  self.publisher = publisher;
  self.subtitle = subtitle;
  self.summary = summary;
  self.title = title;
  self.updated = updated;
  self.annotationsURL = annotationsURL;
  self.analyticsURL = analyticsURL;
  self.alternateURL = alternateURL;
  self.relatedWorksURL = relatedWorksURL;
  self.licensor = licensor;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;
  
  self.acquisition = [[NYPLBookAcquisition alloc] initWithDictionary:dictionary[AcquisitionKey]];
  if(!self.acquisition) return nil;
  
  self.authorStrings = dictionary[AuthorsKey];
  if(!self.authorStrings) return nil;
  
  self.availabilityStatus = [dictionary[AvailabilityStatusKey] integerValue];
  
  self.availableCopies = [dictionary[AvailableCopiesKey] integerValue];
  
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
  
  self.subtitle = NYPLNullToNil(dictionary[SubtitleKey]);
  
  self.summary = NYPLNullToNil(dictionary[SummaryKey]);
  
  self.title = dictionary[TitleKey];
  if(!self.title) return nil;
  
  self.updated = [NSDate dateWithRFC3339String:dictionary[UpdatedKey]];
  if(!self.updated) return nil;
  
  NSString *const annotations = NYPLNullToNil(dictionary[AnnotationsURLKey]);
  self.annotationsURL = annotations ? [NSURL URLWithString:annotations] : nil;
  
  NSString *const alternate = NYPLNullToNil(dictionary[AlternateURLKey]);
  self.alternateURL = alternate ? [NSURL URLWithString:alternate] : nil;

  NSString *const analytics = NYPLNullToNil(dictionary[AnalyticsURLKey]);
  self.analyticsURL = analytics ? [NSURL URLWithString:analytics] : nil;
  
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{AcquisitionKey: [self.acquisition dictionaryRepresentation],
           AuthorsKey: self.authorStrings,
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
           SubtitleKey: NYPLNullFromNil(self.subtitle),
           SummaryKey: NYPLNullFromNil(self.summary),
           TitleKey: self.title,
           UpdatedKey: [self.updated RFC3339String],
           AnnotationsURLKey: NYPLNullFromNil([self.annotationsURL absoluteString]),
           AnalyticsURLKey: NYPLNullFromNil([self.analyticsURL absoluteString]),
           AlternateURLKey: NYPLNullFromNil([self.alternateURL absoluteString])
          };
}

- (NSString *)authors
{
  return [self.authorStrings componentsJoinedByString:@"; "];
}

- (NSString *)categories
{
  return [self.categoryStrings componentsJoinedByString:@"; "];
}

@end
