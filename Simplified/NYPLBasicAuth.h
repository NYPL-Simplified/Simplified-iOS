// This function is used to implement basic authentication handling for NSURLSessionTaskDelegate
// instances by pulling credentials from NYPLAccount.
void NYPLBasicAuthHandler(NSURLAuthenticationChallenge *challenge,
                          void (^completionHandler)
                          (NSURLSessionAuthChallengeDisposition disposition,
                           NSURLCredential *credential));
