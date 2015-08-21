#import "NYPLNull.h"

#import "NYPLBookAcquisition.h"

@interface NYPLBookAcquisition ()

@property (nonatomic) NSURL *borrow;
@property (nonatomic) NSURL *generic;
@property (nonatomic) NSURL *openAccess;
@property (nonatomic) NSURL *sample;

@end

static NSString *const BorrowKey = @"borrow";
static NSString *const GenericKey = @"generic";
static NSString *const OpenAccessKey = @"open-access";
static NSString *const SampleKey = @"sample";

@implementation NYPLBookAcquisition

- (instancetype)initWithBorrow:(NSURL *const)borrow
                       generic:(NSURL *const)generic
                    openAccess:(NSURL *const)openAccess
                        sample:(NSURL *const)sample
{
  self = [super init];
  if(!self) return nil;
  
  self.borrow = borrow;
  self.generic = generic;
  self.openAccess = openAccess;
  self.sample = sample;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;

  self.borrow = [NSURL URLWithString:NYPLNullToNil(dictionary[BorrowKey])];
  self.generic = [NSURL URLWithString:NYPLNullToNil(dictionary[GenericKey])];
  self.openAccess = [NSURL URLWithString:NYPLNullToNil(dictionary[OpenAccessKey])];
  self.sample = [NSURL URLWithString:NYPLNullToNil(dictionary[SampleKey])];
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BorrowKey: NYPLNullFromNil([self.borrow absoluteString]),
           GenericKey: NYPLNullFromNil([self.generic absoluteString]),
           OpenAccessKey: NYPLNullFromNil([self.openAccess absoluteString]),
           SampleKey: NYPLNullFromNil([self.sample absoluteString])};
}

- (NSURL *)preferredURL
{
  // TODO: This currently does not take into account the 'type' attribute of the links in the
  // original OPDS feed. As such, it may end up preferring a link to a type of content that the
  // app cannot handle.
  
  if(self.openAccess) return self.openAccess;
  if(self.borrow) return self.borrow;
  if(self.generic) return self.generic;
  if(self.sample) return self.sample;
  
  return nil;
}

@end
