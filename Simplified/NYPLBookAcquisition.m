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

  self.borrow = dictionary[BorrowKey];
  self.generic = dictionary[GenericKey];
  self.openAccess = dictionary[OpenAccessKey];
  self.sample = dictionary[SampleKey];
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BorrowKey: self.borrow,
           GenericKey: self.generic,
           OpenAccessKey: self.openAccess,
           SampleKey: self.sample};
}

@end
