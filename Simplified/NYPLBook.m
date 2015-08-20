#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBookAcquisition.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"

#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NYPLBookAcquisition *acquisition;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NYPLBookAvailabilityStatus availabilityStatus;
@property (nonatomic) NSInteger availableCopies;
@property (nonatomic) NSDate *availableUntil;
@property (nonatomic) NSArray *categoryStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic) NSURL *imageThumbnailURL;
@property (nonatomic) NSDate *published;
@property (nonatomic) NSString *publisher;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *summary;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

static NSString *const AcquisitionKey = @"acquisition";
static NSString *const AuthorsKey = @"authors";
static NSString *const AvailabilityStatusKey = @"availability-status";
static NSString *const AvailableCopiesKey = @"available-copies";
static NSString *const AvailableUntilKey = @"available-until";
static NSString *const CategoriesKey = @"categories";
static NSString *const IdentifierKey = @"id";
static NSString *const ImageURLKey = @"image";
static NSString *const ImageThumbnailURLKey = @"image-thumbnail";
static NSString *const PublishedKey = @"published";
static NSString *const PublisherKey = @"publisher";
static NSString *const SubtitleKey = @"subtitle";
static NSString *const SummaryKey = @"summary";
static NSString *const TitleKey = @"title";
static NSString *const UpdatedKey = @"updated";

@implementation NYPLBook

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *const)entry
{
  if(!entry) {
    NYPLLOG(@"Failed to create book from nil entry.");
    return nil;
  }
  
  NSURL *borrow, *generic, *openAccess, *sample, *image, *imageThumbnail = nil;
  
  NYPLBookAvailabilityStatus availabilityStatus = NYPLBookAvailabilityStatusUnknown;
  NSInteger availableCopies = 0;
  NSDate *availableUntil = nil;
  for(NYPLOPDSLink *const link in entry.links) {
    if(link.availabilityStatus) {
      if([link.availabilityStatus isEqualToString:@"available"]) {
        availabilityStatus = NYPLBookAvailabilityStatusAvailable;
      } else if([link.availabilityStatus isEqualToString:@"unavailable"]) {
        availabilityStatus = NYPLBookAvailabilityStatusUnavailable;
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
  
  return [[self alloc]
          initWithAcquisition:[[NYPLBookAcquisition alloc]
                               initWithBorrow:borrow
                               generic:generic
                               openAccess:openAccess
                               sample:sample]
          authorStrings:entry.authorStrings
          availabilityStatus: availabilityStatus
          availableCopies:availableCopies
          availableUntil:availableUntil
          categoryStrings:entry.categoryStrings
          identifier:entry.identifier
          imageURL:image
          imageThumbnailURL:imageThumbnail
          published:entry.published
          publisher:entry.publisher
          subtitle:entry.alternativeHeadline
          summary:entry.summary
          title:entry.title
          updated:entry.updated];
}

- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                 availabilityStatus:(NYPLBookAvailabilityStatus)availabilityStatus
                    availableCopies:(NSInteger)availableCopies
                     availableUntil:(NSDate *)availableUntil
                    categoryStrings:(NSArray *)categoryStrings
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                          published:(NSDate *)published
                          publisher:(NSString *)publisher
                           subtitle:(NSString *)subtitle
                            summary:(NSString *)summary
                              title:(NSString *)title
                            updated:(NSDate *)updated
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
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.published = published;
  self.publisher = publisher;
  self.subtitle = subtitle;
  self.summary = summary;
  self.title = title;
  self.updated = updated;
  
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
           IdentifierKey: self.identifier,
           ImageURLKey: NYPLNullFromNil([self.imageURL absoluteString]),
           ImageThumbnailURLKey: NYPLNullFromNil([self.imageThumbnailURL absoluteString]),
           PublishedKey: NYPLNullFromNil([self.published RFC3339String]),
           PublisherKey: NYPLNullFromNil(self.publisher),
           SubtitleKey: NYPLNullFromNil(self.subtitle),
           SummaryKey: NYPLNullFromNil(self.summary),
           TitleKey: self.title,
           UpdatedKey: [self.updated RFC3339String]};
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
