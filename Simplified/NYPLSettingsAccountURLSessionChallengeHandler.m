//
//  NYPLSettingsAccountURLSessionChallengeHandler.m
//  SimplyE
//
//  Created by Ettore Pasquini on 2/21/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import "NYPLSettingsAccountURLSessionChallengeHandler.h"
#import "NYPLBasicAuth.h"

@implementation NYPLSettingsAccountURLSessionChallengeHandler

- (instancetype)initWithUIDelegate:(id<NYPLSettingsAccountUIDelegate>)uiDelegate
{
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _uiDelegate = uiDelegate;
  return self;
}

#pragma mark NSURLSessionDelegate

- (void) URLSession:(__attribute__((unused)) NSURLSession *)session
               task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                              NSURLCredential *credential))completionHandler
{
  NYPLBasicAuthCustomHandler(challenge,
                             completionHandler,
                             self.uiDelegate.username,
                             self.uiDelegate.pin);
}

@end
