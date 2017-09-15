// This class is capable of working with values serializable by NSKeyedArchiver.

@interface NYPLKeychain : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedKeychain;

- (id)objectForKey:(NSString *)key;
- (id)objectForKey:(NSString *)key accessGroup:(NSString *)groupID;

- (void)setObject:(id)value forKey:(NSString *)key;
- (void)setObject:(id const)value forKey:(NSString *const)key accessGroup:(NSString *const)groupID;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *const)key accessGroup:(NSString *const)groupID;

@end
