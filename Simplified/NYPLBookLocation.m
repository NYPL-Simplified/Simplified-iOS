#import "NYPLNull.h"

#import "NYPLBookLocation.h"

@interface NYPLBookLocation ()

@property (nonatomic) NSString *CFI;
@property (nonatomic) NSString *idref;

@end

static NSString *const CFIKey = @"cfi";
static NSString *const idrefKey = @"idref";

@implementation NYPLBookLocation

- (instancetype)initWithCFI:(NSString *const)CFI idref:(NSString *const)idref
{
  self = [super init];
  if(!self) return nil;
 
  if(!idref) {
    @throw NSInvalidArgumentException;
  }
  
  self.CFI = CFI;
  self.idref = idref;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *const)dictionary
{
  self = [super init];
  if(!self) return nil;
  
  self.CFI = NYPLNullToNil(dictionary[CFIKey]);
  if(self.CFI && ![self.CFI isKindOfClass:[NSString class]]) return nil;
  
  self.idref = dictionary[idrefKey];
  if(![self.idref isKindOfClass:[NSString class]]) return nil;
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{CFIKey: NYPLNilToNull(self.CFI),
           idrefKey: self.idref};
}

@end
