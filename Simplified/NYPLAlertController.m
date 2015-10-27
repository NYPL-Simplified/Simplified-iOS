//
//  NYPLAlertController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/27/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLAlertController.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@interface NYPLAlertController ()

@end

@implementation NYPLAlertController

+ (instancetype)alertWithTitle:(NSString *)title error:(NSError *)error
{
  NSString *message;
  
  if ([error.domain isEqual:NSURLErrorDomain]) {
    if (error.code == NSURLErrorNotConnectedToInternet) {
      message = @"NotConnected";
    } else if (error.code == NSURLErrorCancelled) {
      message = @"SettingsAccountViewControllerInvalidCredentials";
    } else if (error.code == NSURLErrorTimedOut) {
      message = @"TimedOut";
    } else {
      message = @"UnknownRequestError";
    }
    
  }
  
#if defined(FEATURE_DRM_CONNECTOR)
  else if ([error.domain isEqual:NYPLADEPTErrorDomain]) {
    if (error.code == NYPLADEPTErrorAuthenticationFailed) {
      message = @"SettingsAccountViewControllerInvalidCredentials";
    } else if (error.code == NYPLADEPTErrorTooManyActivations) {
      message = @"SettingsAccountViewControllerMessageTooManyActivations";
    } else {
      message = @"UnknownRequestError";
    }
  }
#endif
  
  return [self alertWithTitle:title message:message];
}

+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message, ...
{
  if ([title length] > 0) {
    title = NSLocalizedString(title, nil);
  }
  
  if ([message length] > 0) {
    message = NSLocalizedString(message, nil);
    
#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wformat-nonliteral"
    va_list args;
    va_start(args, message);
    message = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
#pragma clang diagnostic pop
  }
  
  if (title.length > 0 || message.length > 0) {
    NYPLAlertController *alertController = [NYPLAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    return alertController;
  }
  
  return nil;
}

+ (instancetype)alertWithProblemDocumentData:(NSData *)data
{
  NSError *jsonError = nil;
  NSDictionary *problemDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
  NSString *title = NSLocalizedString(@"Error", nil);
  NSString *message = NSLocalizedString(@"An error has occurred", nil);
  
  NSURL *typeURL = problemDict[@"type"] ? [NSURL URLWithString:problemDict[@"type"]] : nil;
  NSString *typeDomain = typeURL.host;
  BOOL isSimplifiedError = [typeDomain isEqualToString:@"librarysimplified.org"];
  NSString *lastPath = typeURL.lastPathComponent;
  
  if (isSimplifiedError && [typeURL.resourceSpecifier isEqualToString:@"//librarysimplified.org/terms/problem/cannot-generate-feed"]) {
    title = NSLocalizedString(@"Library Server Error", nil);
    message = NSLocalizedString(@"The library server encountered an error, please try again later", nil);
  }
  
  return [NYPLAlertController alertWithTitle:title message:message];
}

@end
