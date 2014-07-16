// This class is capable of working with values serializble by NSKeyedArchiver.

@interface NYPLKeychain : NSObject

+ (instancetype)sharedKeychain;

- (id)objectForKey:(NSString *)key;

- (void)setObject:(id)value forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

@end
