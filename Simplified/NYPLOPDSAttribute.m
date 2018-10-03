BOOL NYPLOPDSAttributeKeyStringIsActiveFacet(NSString *const string)
{
  return string != nil && [string rangeOfString:@"activeFacet"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;

}

BOOL NYPLOPDSAttributeKeyStringIsFacetGroup(NSString *const string)
{
  return string != nil && [string rangeOfString:@"facetGroup"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;

}

BOOL NYPLOPDSAttributeKeyStringIsFacetGroupType(NSString *const string)
{
  return string != nil && [string rangeOfString:@"facetGroupType"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}
