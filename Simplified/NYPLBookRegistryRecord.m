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
@property (nonatomic) NSArray<NYPLReadiumBookmark *> *readiumBookmarks;
@property (nonatomic) NSArray<NYPLBookLocation *> *genericBookmarks;

@end

static NSString *const BookKey = @"metadata";
static NSString *const LocationKey = @"location";
static NSString *const StateKey = @"state";
static NSString *const FulfillmentIdKey = @"fulfillmentId";
static NSString *const ReadiumBookmarksKey = @"bookmarks";
static NSString *const GenericBookmarksKey = @"genericBookmarks";

@implementation NYPLBookRegistryRecord

- (instancetype)initWithBook:(NYPLBook *const)book
                    location:(NYPLBookLocation *const)location
                       state:(NYPLBookState)state
               fulfillmentId:(NSString *)fulfillmentId
            readiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)readiumBookmarks
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
                   initWithDictionary:NYPLNullToNil(dictionary[LocationKey])];
  if(self.location && ![self.location isKindOfClass:[NYPLBookLocation class]]) return nil;
  
  self.state = [NYPLBookStateHelper bookStateFromString:dictionary[StateKey]];
  
  self.fulfillmentId = NYPLNullToNil(dictionary[FulfillmentIdKey]);
  
  NSMutableArray<NYPLReadiumBookmark *> *readiumBookmarks = [NSMutableArray array];
  for (NSDictionary *dict in NYPLNullToNil(dictionary[ReadiumBookmarksKey])) {
    [readiumBookmarks addObject:[[NYPLReadiumBookmark alloc] initWithDictionary:dict]];
  }
  self.readiumBookmarks = readiumBookmarks;

  NSMutableArray<NYPLBookLocation *> *genericBookmarks = [NSMutableArray array];
  for (NSDictionary *dict in NYPLNullToNil(dictionary[GenericBookmarksKey])) {
    [genericBookmarks addObject:[[NYPLBookLocation alloc] initWithDictionary:dict]];
  }
  self.genericBookmarks = genericBookmarks;
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableArray *readiumBookmarks = [NSMutableArray array];
  for (NYPLReadiumBookmark *readium in self.readiumBookmarks) {
    [readiumBookmarks addObject:readium.dictionaryRepresentation];
  }

  NSMutableArray *genericBookmarks = [NSMutableArray array];
  for (NYPLBookLocation *generic in self.genericBookmarks) {
    [genericBookmarks addObject:generic.dictionaryRepresentation];
  }
  
  return @{BookKey: [self.book dictionaryRepresentation],
           LocationKey: NYPLNullFromNil([self.location dictionaryRepresentation]),
           StateKey: [NYPLBookStateHelper stringValueFromBookState:self.state],
           FulfillmentIdKey: NYPLNullFromNil(self.fulfillmentId),
           ReadiumBookmarksKey: NYPLNullFromNil(readiumBookmarks),
           GenericBookmarksKey: NYPLNullFromNil(genericBookmarks)};
}

- (instancetype)recordWithBook:(NYPLBook *const)book
{
  return [[[self class] alloc] initWithBook:book location:self.location state:self.state fulfillmentId:self.fulfillmentId readiumBookmarks:self.readiumBookmarks genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithLocation:(NYPLBookLocation *const)location
{
  return [[[self class] alloc] initWithBook:self.book location:location state:self.state fulfillmentId:self.fulfillmentId readiumBookmarks:self.readiumBookmarks genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithState:(NYPLBookState const)state
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:state fulfillmentId:self.fulfillmentId readiumBookmarks:self.readiumBookmarks genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithFulfillmentId:(NSString *)fulfillmentId
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:fulfillmentId readiumBookmarks:self.readiumBookmarks genericBookmarks:self.genericBookmarks];
}
  
- (instancetype)recordWithReadiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)bookmarks
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:self.fulfillmentId readiumBookmarks:bookmarks genericBookmarks:self.genericBookmarks];
}

- (instancetype)recordWithGenericBookmarks:(NSArray<NYPLBookLocation *> *)bookmarks
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:self.state fulfillmentId:self.fulfillmentId readiumBookmarks:self.readiumBookmarks genericBookmarks:bookmarks];
}
  
@end
