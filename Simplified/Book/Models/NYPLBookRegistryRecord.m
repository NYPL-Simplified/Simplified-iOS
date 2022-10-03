#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistryRecord.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "SimplyE-Swift.h"

#if FEATURE_AUDIOBOOKS
@import NYPLAudiobookToolkit;
#endif

@interface NYPLBookRegistryRecord ()

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookLocation *location;
@property (nonatomic) NYPLBookState state;
@property (nonatomic) NSString *fulfillmentId;
@property (nonatomic) NSArray<NYPLReadiumBookmark *> *readiumBookmarks;
@property (nonatomic) NSArray<NYPLAudiobookBookmark *> *audiobookBookmarks;
@property (nonatomic) NSArray<NYPLBookLocation *> *genericBookmarks;

@end

static NSString *const BookKey = @"metadata";
static NSString *const StateKey = @"state";
static NSString *const FulfillmentIdKey = @"fulfillmentId";
static NSString *const ReadiumBookmarksKey = @"bookmarks";
static NSString *const AudiobookBookmarksKey = @"audiobookBookmarks";
static NSString *const GenericBookmarksKey = @"genericBookmarks";

@implementation NYPLBookRegistryRecord

- (instancetype)initWithBook:(NYPLBook *const)book
                    location:(NYPLBookLocation *const)location
                       state:(NYPLBookState)state
               fulfillmentId:(NSString *)fulfillmentId
            readiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)readiumBookmarks
#if FEATURE_AUDIOBOOKS
          audiobookBookmarks:(NSArray<NYPLAudiobookBookmark *> *)audiobookBookmarks
#else
          audiobookBookmarks:(NSArray *)audiobookBookmarks
#endif
            genericBookmarks:(NSArray<NYPLBookLocation *> *)genericBookmarks
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.book = book;
  self.location = location;
  self.state = state;
  self.fulfillmentId = fulfillmentId;
  self.readiumBookmarks = readiumBookmarks;
  self.audiobookBookmarks = audiobookBookmarks;
  self.genericBookmarks = genericBookmarks;

  if (!book.defaultAcquisition) {
    // Since the book has no default acqusition, there is no reliable way to
    // determine if the book is on hold (although it may be), nor is there any
    // way to download the book if it is available. As such, we give the book a
    // special "unsupported" state which will allow other parts of the app to
    // ignore it as appropriate. Unsupported books should generally only appear
    // when a user has checked out or reserved a book in an unsupported format
    // using another app.
    self.state = NYPLBookStateUnsupported;
    return self;
  }

  // FIXME: The logic below is confusing at best. Upon initial inspection, it's
  // unclear why `book.state` needs to be "fixed" in this initializer. If said
  // fixing is appropriate, a rationale should be added here.

  // If the book availability indicates that the book is held, make sure the state
  // reflects that.
  __block BOOL actuallyOnHold = NO;
  [book.defaultAcquisition.availability
   matchUnavailable:nil
   limited:nil
   unlimited:nil
   reserved:^(__unused NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved) {
     self.state = NYPLBookStateHolding;
     actuallyOnHold = YES;
   } ready:^(__unused NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready) {
     self.state = NYPLBookStateHolding;
     actuallyOnHold = YES;
   }];

  if (!actuallyOnHold) {
    // Set the correct non-holding state.
    if (self.state == NYPLBookStateHolding || self.state == NYPLBookStateUnsupported)
    {
      // Since we're not in some download-related state and we're not unregistered,
      // we must need to be downloaded.
      self.state = NYPLBookStateDownloadNeeded;
    }
  }
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;
  
  self.book = [[NYPLBook alloc] initWithDictionary:dictionary[BookKey]];
  if(![self.book isKindOfClass:[NYPLBook class]]) return nil;
  
  self.location = [[NYPLBookLocation alloc]
                   initWithDictionary:NYPLNullToNil(dictionary[NYPLBookmarkDictionaryRepresentation.locationKey])];
  if(self.location && ![self.location isKindOfClass:[NYPLBookLocation class]]) return nil;
  
  NSNumber *state = [NYPLBookStateHelper bookStateFromString:dictionary[StateKey]];
  if (state) {
    self.state = state.integerValue;
  } else {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeUnknownBookState
                              summary:@"Invalid nil state during BookRegistryRecord init"
                             metadata:@{
                               @"Input dict": dictionary ?: @"N/A"
                             }];
    @throw NSInvalidArgumentException;
  }
  
  self.fulfillmentId = NYPLNullToNil(dictionary[FulfillmentIdKey]);
  
  NSMutableArray<NYPLReadiumBookmark *> *readiumBookmarks = [NSMutableArray array];
  for (NSDictionary *dict in NYPLNullToNil(dictionary[ReadiumBookmarksKey])) {
    NYPLReadiumBookmark *bookmark = [[NYPLReadiumBookmark alloc] initWithDictionary:dict];
    if (bookmark) {
      [readiumBookmarks addObject:bookmark];
    }
  }
  self.readiumBookmarks = readiumBookmarks;
  
  NSMutableArray<NYPLAudiobookBookmark *> *audiobookBookmarks = [NSMutableArray array];
#if FEATURE_AUDIOBOOKS
  for (NSDictionary *dict in NYPLNullToNil(dictionary[AudiobookBookmarksKey])) {
    NYPLAudiobookBookmark *bookmark = [[NYPLAudiobookBookmark alloc] initWithDictionary:dict];
    if (bookmark) {
      [audiobookBookmarks addObject:bookmark];
    }
  }
#endif
  self.audiobookBookmarks = audiobookBookmarks;

  NSMutableArray<NYPLBookLocation *> *genericBookmarks = [NSMutableArray array];
  for (NSDictionary *dict in NYPLNullToNil(dictionary[GenericBookmarksKey])) {
    NYPLBookLocation *bookmark = [[NYPLBookLocation alloc] initWithDictionary:dict];
    if (bookmark) {
      [genericBookmarks addObject:bookmark];
    }
  }
  self.genericBookmarks = genericBookmarks;
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableArray *readiumBookmarks = [NSMutableArray array];
  for (NYPLReadiumBookmark *readiumBookmark in self.readiumBookmarks) {
    [readiumBookmarks addObject:readiumBookmark.dictionaryRepresentation];
  }
  
  NSMutableArray *audiobookBookmarks = [NSMutableArray array];
#if FEATURE_AUDIOBOOKS
  for (NYPLAudiobookBookmark *audiobookBookmark in self.audiobookBookmarks) {
    [audiobookBookmarks addObject:audiobookBookmark.dictionaryRepresentation];
  }
#endif
  
  NSMutableArray *genericBookmarks = [NSMutableArray array];
  for (NYPLBookLocation *genericBookmark in self.genericBookmarks) {
    [genericBookmarks addObject:genericBookmark.dictionaryRepresentation];
  }
  
  return @{BookKey: [self.book dictionaryRepresentation],
           NYPLBookmarkDictionaryRepresentation.locationKey: NYPLNullFromNil([self.location dictionaryRepresentation]),
           StateKey: [NYPLBookStateHelper stringValueFromBookState:self.state],
           FulfillmentIdKey: NYPLNullFromNil(self.fulfillmentId),
           ReadiumBookmarksKey: NYPLNullFromNil(readiumBookmarks),
           AudiobookBookmarksKey: NYPLNullFromNil(audiobookBookmarks),
           GenericBookmarksKey: NYPLNullFromNil(genericBookmarks)};
}

- (instancetype)recordWithBook:(NYPLBook *const)book
{
  return [[[self class] alloc] initWithBook:book
                                   location:self.location
                                      state:self.state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithLocation:(NYPLBookLocation *const)location
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:location
                                      state:self.state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithState:(NYPLBookState const)state
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:self.location
                                      state:state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithFulfillmentId:(NSString *)fulfillmentId
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:self.location
                                      state:self.state
                              fulfillmentId:fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:self.genericBookmarks];
}
  
- (instancetype)recordWithReadiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)bookmarks
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:self.location
                                      state:self.state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:bookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:self.genericBookmarks];
}

#if FEATURE_AUDIOBOOKS
- (instancetype)recordWithAudiobookBookmarks:(NSArray<NYPLAudiobookBookmark *> *)bookmarks
#else
- (instancetype)recordWithAudiobookBookmarks:(NSArray *)bookmarks
#endif
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:self.location
                                      state:self.state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:bookmarks
                           genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithGenericBookmarks:(NSArray<NYPLBookLocation *> *)bookmarks
{
  return [[[self class] alloc] initWithBook:self.book
                                   location:self.location
                                      state:self.state
                              fulfillmentId:self.fulfillmentId
                           readiumBookmarks:self.readiumBookmarks
                         audiobookBookmarks:self.audiobookBookmarks
                           genericBookmarks:bookmarks];
}
  
@end
