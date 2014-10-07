BOOL NYPLOPDSAttributeKeyStringIsActiveFacet(NSString *const string)
{
  if(!string) return NO;
  
  return [string rangeOfString:@"activeFacet"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}

BOOL NYPLOPDSAttributeKeyStringIsFacetGroup(NSString *const string)
{
  if(!string) return NO;
  
  return [string rangeOfString:@"facetGroup"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}