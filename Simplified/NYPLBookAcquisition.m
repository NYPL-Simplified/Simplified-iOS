#import "NYPLNull.h"

#import "NYPLBookAcquisition.h"

@interface NYPLBookAcquisition ()

@property (nonatomic) NSURL *borrow;
@property (nonatomic) NSURL *generic;
@property (nonatomic) NSURL *openAccess;
@property (nonatomic) NSURL *revoke;
@property (nonatomic) NSURL *sample;

@end

static NSString *const BorrowKey = @"borrow";
static NSString *const GenericKey = @"generic";
static NSString *const OpenAccessKey = @"open-access";
static NSString *const RevokeKey = @"revoke";
static NSString *const SampleKey = @"sample";

@implementation NYPLBookAcquisition

- (instancetype)initWithBorrow:(NSURL *const)borrow
                       generic:(NSURL *const)generic
                    openAccess:(NSURL *const)openAccess
                        revoke:(NSURL *const)revoke
                        sample:(NSURL *const)sample
{
  self = [super init];
  if(!self) return nil;
  
  self.borrow = borrow;
  self.generic = generic;
  self.openAccess = openAccess;
  self.revoke = revoke;
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
  self.revoke = [NSURL URLWithString:NYPLNullToNil(dictionary[RevokeKey])];
  self.sample = [NSURL URLWithString:NYPLNullToNil(dictionary[SampleKey])];
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BorrowKey: NYPLNullFromNil([self.borrow absoluteString]),
           GenericKey: NYPLNullFromNil([self.generic absoluteString]),
           OpenAccessKey: NYPLNullFromNil([self.openAccess absoluteString]),
           RevokeKey: NYPLNullFromNil([self.revoke absoluteString]),
           SampleKey: NYPLNullFromNil([self.sample absoluteString])};
}

@end
