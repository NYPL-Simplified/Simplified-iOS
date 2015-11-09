#ifndef Simplified_NYPLLOG_h
#define Simplified_NYPLLOG_h

#include <stdarg.h>

typedef void (^NYPLLOG_LogCallbackBlock)(NSString * _Nullable logLevel,  NSString * _Nullable exceptionNameOrNil, NSDictionary * _Nullable withDataOrNil, NSString * _Nullable message);
static _Nullable NYPLLOG_LogCallbackBlock s_logCallbackBlock = nil;

#define NYPLLOG(logLevel, exception, data, s) \
  NSLog(@"%@: %@", [NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding], s); \
  if (s_logCallbackBlock) \
    s_logCallbackBlock(logLevel, exception, data, s)

#define NYPLLOG_F(level, exception, data, s, ...) \
  NSString *msg = [NSString stringWithFormat:s, __VA_ARGS__]; \
  NYPLLOG(level, exception, data, msg)

#endif
