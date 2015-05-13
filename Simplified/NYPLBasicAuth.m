#import "NYPLAccount.h"

#import "NYPLBasicAuth.h"

void NYPLBasicAuthHandler(NSURLAuthenticationChallenge *const challenge,
                          void (^completionHandler)
                          (NSURLSessionAuthChallengeDisposition disposition,
                           NSURLCredential *credential))
{
  if([challenge.protectionSpace.authenticationMethod
      isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
    if([[NYPLAccount sharedAccount] hasBarcodeAndPIN] && challenge.previousFailureCount == 0) {
      completionHandler(NSURLSessionAuthChallengeUseCredential,
                        [NSURLCredential
                         credentialWithUser:[NYPLAccount sharedAccount].barcode
                         password:[NYPLAccount sharedAccount].PIN
                         persistence:NSURLCredentialPersistenceNone]);
    } else {
      completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}

void NYPLBasicAuthCustomHandler(NSURLAuthenticationChallenge *challenge,
                                void (^completionHandler)
                                (NSURLSessionAuthChallengeDisposition disposition,
                                 NSURLCredential *credential),
                                NSString *const username,
                                NSString *const password)
{
  if(!(username && password)) {
    @throw NSInvalidArgumentException;
  }
  
  if([challenge.protectionSpace.authenticationMethod
      isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
    if(challenge.previousFailureCount == 0) {
      completionHandler(NSURLSessionAuthChallengeUseCredential,
                        [NSURLCredential
                         credentialWithUser:username
                         password:password
                         persistence:NSURLCredentialPersistenceNone]);
    } else {
      completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}