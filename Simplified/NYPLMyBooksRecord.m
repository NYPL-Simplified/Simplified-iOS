#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLMyBooksRecord.h"
#import "NYPLNull.h"

@interface NYPLMyBooksRecord ()

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookLocation *location;
@property (nonatomic) NYPLMyBooksState state;

@end

static NSString *const BookKey = @"metadata";
static NSString *const LocationKey = @"location";
static NSString *const StateKey = @"state";

@implementation NYPLMyBooksRecord

- (instancetype)initWithBook:(NYPLBook *const)book
                    location:(NYPLBookLocation *const)location
                       state:(NYPLMyBooksState const)state
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.book = book;
  self.location = location;
  self.state = state;
  
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
  
  self.state = NYPLMyBooksStateFromString(dictionary[StateKey]);
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BookKey: [self.book dictionaryRepresentation],
           LocationKey: NYPLNullFromNil([self.location dictionaryRepresentation]),
           StateKey: NYPLMyBooksStateToString(self.state)};
}

- (instancetype)recordWithBook:(NYPLBook *const)book
{
  return [[[self class] alloc] initWithBook:book location:self.location state:self.state];
}

- (instancetype)recordWithLocation:(NYPLBookLocation *const)location
{
  return [[[self class] alloc] initWithBook:self.book location:location state:self.state];
}

- (instancetype)recordWithState:(NYPLMyBooksState const)state
{
  return [[[self class] alloc] initWithBook:self.book location:self.location state:state];
}

@end
