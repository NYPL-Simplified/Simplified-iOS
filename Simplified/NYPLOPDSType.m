#import "NYPLOPDSType.h"

BOOL NYPLOPDSTypeStringIsAcquisition(NSString *const string)
{
  if(!string) return NO;
  
  return [string rangeOfString:@"acquisition"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}

BOOL NYPLOPDSTypeStringIsNavigation(NSString *const string)
{
  if(!string) return NO;
  
  return [string rangeOfString:@"navigation"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}

BOOL NYPLOPDSTypeStringIsOpenSearchDescription(NSString *string)
{
  if(!string) return NO;
    
  return [string rangeOfString:@"application/opensearchdescription+xml"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}