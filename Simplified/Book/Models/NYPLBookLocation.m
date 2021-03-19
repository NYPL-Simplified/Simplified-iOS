#import "NYPLBookLocation.h"

@interface NYPLBookLocation ()

@property (nonatomic) NSString *locationString;
@property (nonatomic) NSString *renderer;

@end

static NSString *const locationStringKey = @"locationString";
static NSString *const rendererKey = @"renderer";

@implementation NYPLBookLocation

- (instancetype)initWithLocationString:(NSString *const)locationString
                              renderer:(NSString *const)renderer
{
  self = [super init];
  if(!self) return nil;
 
  if(!(locationString && renderer)) {
    @throw NSInvalidArgumentException;
  }
  
  self.locationString = locationString;
  self.renderer = renderer;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *const)dictionary
{
  self = [super init];
  if(!self) return nil;
  
  self.locationString = dictionary[locationStringKey];
  if(![self.locationString isKindOfClass:[NSString class]]) return nil;
  
  self.renderer = dictionary[rendererKey];
  if(![self.renderer isKindOfClass:[NSString class]]) return nil;
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{locationStringKey: self.locationString,
           rendererKey: self.renderer};
}

@end
