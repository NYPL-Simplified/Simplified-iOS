#import "NYPLKeychain.h"

@implementation NYPLKeychain

+ (instancetype)sharedKeychain
{
  static dispatch_once_t predicate;
  static NYPLKeychain *sharedKeychain = nil;
  
  dispatch_once(&predicate, ^{
    sharedKeychain = [[self alloc] init];
    if(!sharedKeychain) {
      NYPLLOG(@"Failed to created shared keychain.");
    }
  });
  
  return sharedKeychain;
}

- (NSMutableDictionary *)defaultDictionary
{
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  dictionary[(__bridge __strong id) kSecClass] = (__bridge id) kSecClassGenericPassword;
  
  return dictionary;
}

- (id)objectForKey:(NSString *)key
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  dictionary[(__bridge __strong id) kSecMatchLimit] = (__bridge id) kSecMatchLimitOne;
  dictionary[(__bridge __strong id) kSecReturnData] = (__bridge id) kCFBooleanTrue;
  
  CFTypeRef resultRef = NULL;
  SecItemCopyMatching((__bridge CFDictionaryRef) dictionary, &resultRef);
  
  NSData *result = (__bridge_transfer NSData *) resultRef;
  if(!result) return nil;
  
  return [NSKeyedUnarchiver unarchiveObjectWithData:result];
}

- (void)setObject:(id)value forKey:(NSString *)key
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  NSData *const valueData = [NSKeyedArchiver archivedDataWithRootObject:value];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  
  if([self objectForKey:key]) {
    NSMutableDictionary *const updateDictionary = [NSMutableDictionary dictionary];
    updateDictionary[(__bridge __strong id) kSecValueData] = valueData;
    SecItemUpdate((__bridge CFDictionaryRef) dictionary,
                  (__bridge CFDictionaryRef) updateDictionary);
  } else {
    dictionary[(__bridge __strong id) kSecValueData] = valueData;
    SecItemAdd((__bridge CFDictionaryRef) dictionary, NULL);
  }
}

- (void)removeObjectForKey:(NSString *)key
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  
  SecItemDelete((__bridge CFDictionaryRef) dictionary);
}

@end
