#import "NYPLMyBooksRecord.h"

@interface NYPLMyBooksRecord ()

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLMyBooksState state;

@end

static NSString *const BookKey = @"metadata";
static NSString *const StateKey = @"state";

@implementation NYPLMyBooksRecord

+ (instancetype)recordWithDictionary:(NSDictionary *const)dictionary
{
  NYPLBook *const book = [[NYPLBook alloc] initWithDictionary:dictionary[BookKey]];
  NYPLMyBooksState const state = NYPLMyBooksStateFromString(dictionary[StateKey]);
  return [[self alloc] initWithBook:book state:state];
}

- (instancetype)initWithBook:(NYPLBook *)book state:(NYPLMyBooksState)state
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.book = book;
  self.state = state;
  
  return self;
}

- (instancetype)recordWithBook:(NYPLBook *)book
{
  return [[[self class] alloc] initWithBook:book state:self.state];
}

- (instancetype)recordWithState:(NYPLMyBooksState)state
{
  return [[[self class] alloc] initWithBook:self.book state:state];
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BookKey: [self.book dictionaryRepresentation],
           StateKey: NYPLMyBooksStateToString(self.state)};
}

@end
