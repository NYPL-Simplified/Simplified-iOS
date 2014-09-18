@interface NSString (NYPLStringAdditions)

- (NSString *)fileSystemSafeBase64DecodedStringUsingEncoding:(NSStringEncoding)encoding;

- (NSString *)fileSystemSafeBase64EncodedStringUsingEncoding:(NSStringEncoding)encoding;

- (NSString *)stringByURLEncoding;

@end
