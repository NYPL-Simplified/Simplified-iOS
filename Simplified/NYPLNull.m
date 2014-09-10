#import "NYPLNull.h"

id NYPLNullFromNil(id object)
{
  return object ? object : [NSNull null];
}

id NYPLNullToNil(id object)
{
  return [object isKindOfClass:[NSNull class]] ? nil : object;
}