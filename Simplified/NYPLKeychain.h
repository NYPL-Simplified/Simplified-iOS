// This class is capable of working with values serializble by NSKeyedArchiver.

@interface NYPLKeychain : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedKeychain;

- (id)objectForKey:(NSString *)key;

- (void)setObject:(id)value forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

@end
