#import "NYPLOPDSType.h"

BOOL NYPLOPDSTypeStringIsAcquisition(NSString *const string)
{
  return string != nil && [string rangeOfString:@"acquisition"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;

}

BOOL NYPLOPDSTypeStringIsNavigation(NSString *const string)
{
  return string != nil && [string rangeOfString:@"navigation"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;

}

BOOL NYPLOPDSTypeStringIsOpenSearchDescription(NSString *string)
{
  return string != nil && [string rangeOfString:@"application/opensearchdescription+xml"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;

}