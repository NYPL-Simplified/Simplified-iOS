#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistryRecord.h"
#import "NYPLNull.h"
#import "NYPLOPDS.h"
#import "SimplyE-Swift.h"

@interface NYPLBookRegistryRecord ()

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookLocation *location;
@property (nonatomic) NYPLBookState state;
@property (nonatomic) NSString *fulfillmentId;
@property (nonatomic) NSArray<NYPLReaderBookmark *> *bookmarks;
@property (nonatomic) NYPLHoldsNotificationState holdsNotificationState;

@end

static NSString *const BookKey = @"metadata";
static NSString *const LocationKey = @"location";
static NSString *const StateKey = @"state";
static NSString *const FulfillmentIdKey = @"fulfillmentId";
static NSString *const BookmarksKey = @"bookmarks";
static NSString *const HoldsNotificationStateKey = @"holdsNotificationState";

@implementation NYPLBookRegistryRecord

- (instancetype)initWithBook:(NYPLBook *)book
                    location:(NYPLBookLocation *)location
                       state:(NYPLBookState)state
               fulfillmentId:(NSString *)fulfillmentId
                   bookmarks:(NSArray<NYPLReaderBookmark *> *)bookmarks
      holdsNotificationState:(NYPLHoldsNotificationState)holdsNotificationState
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
  if (bookmarks != nil) {
    self.bookmarks = bookmarks;
  }
  else {
    self.bookmarks = [[NSMutableArray alloc] init];
  }

  if (holdsNotificationState) {
    self.holdsNotificationState = holdsNotificationState;
  }
  else {
    self.holdsNotificationState = NYPLHoldsNotificationStateNotApplicable;
  }

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
    if (!((NYPLBookStateDownloadFailed |
           NYPLBookStateDownloading |
           NYPLBookStateDownloadNeeded |
           NYPLBookStateDownloadSuccessful |
           NYPLBookStateUsed)
          & self.state)
        && self.state != NYPLBookStateUnregistered)
    {
      // Since we're not in some download-related state and we're not unregistered,
      // we must need to be downloaded.
      self.state = NYPLBookStateDownloadNeeded;
    }
  }

  return self;
}

// This function has been refactored and for now must remain,
// Until we have some type of data migration in place so that the NYPLBookRegistryRecord doesn't break
// between the period before the HoldsNotificationState is added to the Record and after the
// HoldsNotificationState is added to the Record
- (instancetype)initWithBook:(NYPLBook *const)book
                    location:(NYPLBookLocation *const)location
                       state:(NYPLBookState)state
               fulfillmentId:(NSString *)fulfillmentId
                   bookmarks:(NSArray<NYPLReaderBookmark *> *)bookmarks
{
  NYPLHoldsNotificationState holdsNotificationState = NYPLHoldsNotificationStateNotApplicable;
  return [self initWithBook:book location:location state:state fulfillmentId:fulfillmentId bookmarks:bookmarks holdsNotificationState:holdsNotificationState];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;
  
  self.book = [[NYPLBook alloc] initWithDictionary:dictionary[BookKey]];
  if(![self.book isKindOfClass:[NYPLBook class]]) return nil;
  
  self.location = [[NYPLBookLocation alloc]
                   initWithDictionary:NYPLNullToNil(dictionary[LocationKey])];
  if(self.location && ![self.location isKindOfClass:[NYPLBookLocation class]]) return nil;
  
  self.state = NYPLBookStateFromString(dictionary[StateKey]);
  
  self.fulfillmentId = NYPLNullToNil(dictionary[FulfillmentIdKey]);
  
  NSMutableArray<NYPLReaderBookmark *> *bookmarks = [[NSMutableArray alloc] init];
  
  // bookmarks from dictionary to elements
  for (NSDictionary *dict in NYPLNullToNil(dictionary[BookmarksKey])) {
    
    [bookmarks addObject:[[NYPLReaderBookmark alloc] initWithDictionary:dict]];
    
  }
  
  self.bookmarks = bookmarks;

  if (NYPLHoldsNotificationStateFromString(dictionary[HoldsNotificationStateKey])) {
    self.holdsNotificationState = NYPLHoldsNotificationStateFromString(dictionary[HoldsNotificationStateKey]);
  }

  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableArray *bookmarkDictionaries = [[NSMutableArray alloc] init];
  
  for (NYPLReaderBookmark *element in self.bookmarks) {
    
    [bookmarkDictionaries addObject:element.dictionaryRepresentation];
    
  }

  return @{BookKey: [self.book dictionaryRepresentation],
           LocationKey: NYPLNullFromNil([self.location dictionaryRepresentation]),
           StateKey: NYPLBookStateToString(self.state),
           FulfillmentIdKey: NYPLNullFromNil(self.fulfillmentId),
           BookmarksKey: NYPLNullToNil(bookmarkDictionaries),
           HoldsNotificationStateKey:NYPLHoldsNotificationStateToString(self.holdsNotificationState)};
}

- (instancetype)recordWithBook:(NYPLBook *const)book
{
  return [[[self class] alloc] initWithBook:book location:self.location state:self.state fulfillmentId:self.fulfillmentId bookmarks:self.bookmarks holdsNotificationState:self.holdsNotificationState];
}

- (instancetype)recordWithLocation:(NYPLBookLocation *const)location
{
  return [[[self class] alloc] initWithBook:self.book location:location state:self.state fulfillmentId:self.fulfillmentId bookmarks:self.bookmarks holdsNotificationState:self.holdsNotificationState];
}

- (instancetype)recordWithState:(NYPLBookState const)state
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:state fulfillmentId:self.fulfillmentId bookmarks:self.bookmarks holdsNotificationState:self.holdsNotificationState];
}

- (instancetype)recordWithFulfillmentId:(NSString *)fulfillmentId
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:fulfillmentId bookmarks:self.bookmarks holdsNotificationState:self.holdsNotificationState];
}
  
- (instancetype)recordWithBookmarks:(NSArray *)bookmarks
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:self.fulfillmentId bookmarks:bookmarks holdsNotificationState:self.holdsNotificationState];
}

- (instancetype)recordWithHoldsNotificationState:(NYPLHoldsNotificationState)holdsNotificationState
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:self.fulfillmentId bookmarks:self.bookmarks holdsNotificationState:holdsNotificationState];
}

@end
