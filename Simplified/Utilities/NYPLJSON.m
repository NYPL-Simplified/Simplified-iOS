#import "NYPLJSON.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"

NSData *NYPLJSONDataFromObject(id const object)
{
  return [NSJSONSerialization dataWithJSONObject:object
                                         options:0
                                           error:NULL];
}

id NYPLJSONObjectFromData(NSData *const data)
{
  return [NSJSONSerialization JSONObjectWithData:data
                                         options:0
                                           error:NULL];
}

#pragma clang diagnostic pop
