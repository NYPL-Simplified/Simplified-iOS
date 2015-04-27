#ifndef Simplified_NYPLLOG_h
#define Simplified_NYPLLOG_h

#define NYPLLOG(s) NSLog(@"%@: %@", [self class], s)

#ifndef __cplusplus
#define NYPLLOG_F(s, ...) NSLog(@"%@: %@", [self class], [NSString stringWithFormat:s, __VA_ARGS__])
#endif

#endif
