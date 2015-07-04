#ifndef Simplified_NYPLLOG_h
#define Simplified_NYPLLOG_h

#define NYPLLOG(s) \
  NSLog(@"%@: %@", [NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding], s)

#define NYPLLOG_F(s, ...) \
  NSLog(@"%@: %@", \
   [NSString stringWithCString:__FUNCTION__ encoding:NSUTF8StringEncoding], \
   [NSString stringWithFormat:s, \
   __VA_ARGS__])

#endif
