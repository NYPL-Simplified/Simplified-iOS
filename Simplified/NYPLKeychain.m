#import "NYPLKeychain.h"

@implementation NYPLKeychain

+ (instancetype)sharedKeychain
{
  static NYPLKeychain *sharedKeychain = nil;
  
  // According to http://stackoverflow.com/questions/22082996/testing-the-keychain-osstatus-error-34018
  //  instantiating the keychain via GCD can cause errors later when trying to add to the keychain
  if (sharedKeychain == nil) {
    sharedKeychain = [[self alloc] init];
    if(!sharedKeychain) {
      NYPLLOG(@"error", @"Failed to created shared keychain.");
    }
  }
  
  return sharedKeychain;
}

- (NSMutableDictionary *const)defaultDictionary
{
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  dictionary[(__bridge __strong id) kSecClass] = (__bridge id) kSecClassGenericPassword;
  
  return dictionary;
}

- (id)objectForKey:(NSString *const)key
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  dictionary[(__bridge __strong id) kSecMatchLimit] = (__bridge id) kSecMatchLimitOne;
  dictionary[(__bridge __strong id) kSecReturnData] = (__bridge id) kCFBooleanTrue;
  
  CFTypeRef resultRef = NULL;
  SecItemCopyMatching((__bridge CFDictionaryRef) dictionary, &resultRef);
  
  NSData *const result = (__bridge_transfer NSData *) resultRef;
  if(!result) return nil;
  
  return [NSKeyedUnarchiver unarchiveObjectWithData:result];
}

- (void)setObject:(id const)value forKey:(NSString *const)key
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
    OSStatus status;
    dictionary[(__bridge __strong id) kSecValueData] = valueData;
    status = SecItemAdd((__bridge CFDictionaryRef) dictionary, NULL);
    if (status != noErr) {
      NYPLLOG(@"error", @"Failed to write secure values to keychain. This is a known issue when running from the debugger");
    }
  }
}

- (void)removeObjectForKey:(NSString *const)key
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  
  SecItemDelete((__bridge CFDictionaryRef) dictionary);
}

@end
