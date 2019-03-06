#import "NYPLAccount.h"

#import "NYPLBasicAuth.h"

void NYPLBasicAuthHandler(NSURLAuthenticationChallenge *const challenge,
                          void (^completionHandler)
                          (NSURLSessionAuthChallengeDisposition disposition,
                           NSURLCredential *credential))
{
  if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
    if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
      NSString *const barcode = [NYPLAccount sharedAccount].barcode;
      NSString *const PIN = [NYPLAccount sharedAccount].PIN;
      NYPLBasicAuthCustomHandler(challenge, completionHandler, barcode, PIN);
    } else {
      completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    return;
  } else if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    return;
  } else {
    NYPLLOG(@"NSURLAuthenticationChallenge rejected.");
    completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    return;
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
  
  if(![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
    completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    return;
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
