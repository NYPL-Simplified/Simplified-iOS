
#import "NYPLAlertView.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLAlertView

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
    return [[self alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
  }
  
  return nil;
}

@end
