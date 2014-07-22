@interface NSMutableURLRequest (NYPLBasicAuthenticationAdditions)

- (void)setBasicAuthenticationUsername:(NSString *)username
                              password:(NSString *)password;

@end
