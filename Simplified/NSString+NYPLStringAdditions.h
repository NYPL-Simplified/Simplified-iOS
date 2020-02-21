@interface NSString (NYPLStringAdditions)

- (NSString *)fileSystemSafeBase64DecodedStringUsingEncoding:(NSStringEncoding)encoding;

- (NSString *)fileSystemSafeBase64EncodedStringUsingEncoding:(NSStringEncoding)encoding;

- (NSString *)SHA256;

/**
 @returns A string made with the assumption that the receiver is a query
 param value.
 */
- (NSString *)stringURLEncodedAsQueryParamValue;

@end
