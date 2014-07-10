#import "NSDate+NYPLDateAdditions.h"
#import "NYPLNull.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"

#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NYPLBookAcquisition *acquisition;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSURL *imageURL; // nilable
@property (nonatomic) NSURL *imageThumbnailURL; // nilable
@property (nonatomic) NYPLBookState state;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

static NSString *const AcquisitionKey = @"acquisition";
static NSString *const AuthorsKey = @"authors";
static NSString *const IdentifierKey = @"id";
static NSString *const ImageURLKey = @"image";
static NSString *const ImageThumbnailURLKey = @"image-thumbnail";
static NSString *const StateKey = @"state";
static NSString *const TitleKey = @"title";
static NSString *const UpdatedKey = @"updated";

static NSString *const StateDefaultKey = @"default";

NSString *StringFromState(NYPLBookState const state)
{
  switch(state) {
    case NYPLBookStateDefault:
      return StateDefaultKey;
  }
}

NYPLBookState StateFromString(NSString *const string)
{
  if([string isEqualToString:StateDefaultKey]) return NYPLBookStateDefault;
  
  @throw NSInvalidArgumentException;
}

@implementation NYPLBook

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *const)entry state:(NYPLBookState)state
{
  if(!entry) {
    NYPLLOG(@"Failed to create book from nil entry.");
    return nil;
  }
  
  NSURL *borrow, *generic, *openAccess, *sample, *image, *imageThumbnail = nil;
  
  for(NYPLOPDSLink *const link in entry.links) {
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
          identifier:entry.identifier
          imageURL:image
          imageThumbnailURL:imageThumbnail
          state:state
          title:entry.title
          updated:entry.updated];
}

- (instancetype)initWithAcquisition:(NYPLBookAcquisition *const)acquisition
                      authorStrings:(NSArray *const)authorStrings
                         identifier:(NSString *const)identifier
                           imageURL:(NSURL *const)imageURL
                  imageThumbnailURL:(NSURL *const)imageThumbnailURL
                              state:(NYPLBookState)state
                              title:(NSString *const)title
                            updated:(NSDate *const)updated
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
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.state = state;
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
  
  self.identifier = dictionary[IdentifierKey];
  if(!self.identifier) return nil;
  
  NSString *const image = NYPLNullToNil(dictionary[ImageURLKey]);
  self.imageURL = image ? [NSURL URLWithString:image] : nil;
  
  NSString *const imageThumbnail = NYPLNullToNil(dictionary[ImageThumbnailURLKey]);
  self.imageThumbnailURL = imageThumbnail ? [NSURL URLWithString:imageThumbnail] : nil;
  
  NSString *const stateString = dictionary[StateKey];
  if(!stateString) return nil;
  self.state = StateFromString(stateString);
  
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
           IdentifierKey: self.identifier,
           ImageURLKey: NYPLNilToNull([self.imageURL absoluteString]),
           ImageThumbnailURLKey: NYPLNilToNull([self.imageThumbnailURL absoluteString]),
           StateKey: StringFromState(self.state),
           TitleKey: self.title,
           UpdatedKey: [self.updated RFC3339String]};
}

@end
