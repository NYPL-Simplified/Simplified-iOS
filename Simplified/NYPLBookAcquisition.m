#import "NYPLNull.h"

#import "NYPLBookAcquisition.h"

@interface NYPLBookAcquisition ()

@property (nonatomic) NSURL *borrow;
@property (nonatomic) NSURL *generic;
@property (nonatomic) NSURL *openAccess;
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
                       generic:(NSURL *const)generic
                    openAccess:(NSURL *const)openAccess
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
  self.generic = [NSURL URLWithString:NYPLNullToNil(dictionary[BorrowKey])];
  self.openAccess = [NSURL URLWithString:NYPLNullToNil(dictionary[BorrowKey])];
  self.revoke = [NSURL URLWithString:NYPLNullToNil(dictionary[RevokeKey])];
  self.sample = [NSURL URLWithString:NYPLNullToNil(dictionary[SampleKey])];
  self.report = [NSURL URLWithString:NYPLNullToNil(dictionary[ReportKey])];
  
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        
        //@property (nonatomic) NSURL *borrow;
        self.borrow = [decoder decodeObjectForKey:@"borrow"];
        
        //@property (nonatomic) NSURL *generic;
        self.generic = [decoder decodeObjectForKey:@"generic"];
        
        //@property (nonatomic) NSURL *openAccess;
        self.openAccess = [decoder decodeObjectForKey:@"openAccess"];
        
        //@property (nonatomic) NSURL *revoke;
        self.revoke = [decoder decodeObjectForKey:@"revoke"];
        
        //@property (nonatomic) NSURL *sample;
        self.sample = [decoder decodeObjectForKey:@"sample"];
        
        //@property (nonatomic) NSURL *report;
        self.report = [decoder decodeObjectForKey:@"report"];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    //@property (nonatomic) NSURL *borrow;
    [encoder encodeObject:self.borrow forKey:@"borrow"];
    
    //@property (nonatomic) NSURL *generic;
    [encoder encodeObject:self.generic forKey:@"generic"];
    
    //@property (nonatomic) NSURL *openAccess;
    [encoder encodeObject:self.openAccess forKey:@"openAccess"];
    
    //@property (nonatomic) NSURL *revoke;
    [encoder encodeObject:self.revoke forKey:@"revoke"];
    
    //@property (nonatomic) NSURL *sample;
    [encoder encodeObject:self.sample forKey:@"sample"];
    
    //@property (nonatomic) NSURL *report;
    [encoder encodeObject:self.report forKey:@"report"];
    
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{BorrowKey: NYPLNullFromNil([self.borrow absoluteString]),
           GenericKey: NYPLNullFromNil([self.generic absoluteString]),
           OpenAccessKey: NYPLNullFromNil([self.openAccess absoluteString]),
           RevokeKey: NYPLNullFromNil([self.revoke absoluteString]),
           SampleKey: NYPLNullFromNil([self.sample absoluteString]),
           ReportKey: NYPLNullFromNil([self.report absoluteString])};
}

@end
