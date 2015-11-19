#import "NYPLNull.h"

#import "NYPLBookAcquisition.h"

@implementation NSDictionary (AcquisitionURLSerialization)

- (NSDictionary *)serializedURLDictionary
{
  NSMutableDictionary *d = [NSMutableDictionary dictionary];
  for (NSString *s in self.allKeys)
    [d setObject:[(NSURL *)[self objectForKey:s] absoluteString] forKey:s];
  return [NSDictionary dictionaryWithDictionary:d];
}

- (NSDictionary *)deserializedURLDictionary
{
  NSMutableDictionary *d = [NSMutableDictionary dictionary];
  for (NSString *s in self.allKeys)
    [d setObject:[NSURL URLWithString:[self objectForKey:s]] forKey:s];
  return [NSDictionary dictionaryWithDictionary:d];
}

@end

@interface NYPLBookAcquisition ()

@property (nonatomic) NSURL *borrow;
@property (nonatomic) NSDictionary *generic;
@property (nonatomic) NSDictionary *openAccess;
@property (nonatomic) NSURL *revoke;
@property (nonatomic) NSURL *sample;
@property (nonatomic) NSURL *report;

@end

static NSString *const BorrowKey = @"borrow";
static NSString *const GenericKey = @"generic";
static NSString *const OpenAccessKey = @"open-access";
static NSString *const RevokeKey = @"revoke";
static NSString *const SampleKey = @"sample";
static NSString *const ReportKey = @"report";

@implementation NYPLBookAcquisition

- (instancetype)initWithBorrow:(NSURL *const)borrow
                       generic:(NSDictionary *const)generic
                    openAccess:(NSDictionary *const)openAccess
                        revoke:(NSURL *const)revoke
                        sample:(NSURL *const)sample
                        report:(NSURL *const)report
{
  self = [super init];
  if(!self) return nil;
  
  self.borrow = borrow;
  self.generic = generic;
  self.openAccess = openAccess;
  self.revoke = revoke;
  self.sample = sample;
  self.report = report;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if(!self) return nil;

  self.borrow = [NSURL URLWithString:NYPLNullToNil(dictionary[BorrowKey])];
  
  // Generic and openAccess used to be strings, so we check here for strings just in case
  if ([dictionary[GenericKey] isKindOfClass:[NSString class]])
    self.generic = @{@"application/epub+zip":[NSURL URLWithString:NYPLNullToNil(dictionary[GenericKey])]};
  else
    self.generic = [NYPLNullToNil(dictionary[GenericKey]) deserializedURLDictionary];
  
  if ([dictionary[OpenAccessKey] isKindOfClass:[NSString class]])
    self.openAccess = @{@"application/epub+zip":[NSURL URLWithString:NYPLNullToNil(dictionary[OpenAccessKey])]};
  else
    self.openAccess = [NYPLNullToNil(dictionary[OpenAccessKey]) deserializedURLDictionary];
  self.revoke = [NSURL URLWithString:NYPLNullToNil(dictionary[RevokeKey])];
  self.sample = [NSURL URLWithString:NYPLNullToNil(dictionary[SampleKey])];
  self.report = [NSURL URLWithString:NYPLNullToNil(dictionary[ReportKey])];
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BorrowKey: NYPLNullFromNil([self.borrow absoluteString]),
           GenericKey: NYPLNullFromNil([self.generic serializedURLDictionary]),
           OpenAccessKey: NYPLNullFromNil([self.openAccess serializedURLDictionary]),
           RevokeKey: NYPLNullFromNil([self.revoke absoluteString]),
           SampleKey: NYPLNullFromNil([self.sample absoluteString]),
           ReportKey: NYPLNullFromNil([self.report absoluteString])};
}

@end
