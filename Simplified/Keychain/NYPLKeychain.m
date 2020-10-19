#import "NYPLKeychain.h"

#import "SimplyE-Swift.h"

@implementation NYPLKeychain

+ (instancetype)sharedKeychain
{
  static NYPLKeychain *sharedKeychain = nil;
  
  // According to http://stackoverflow.com/questions/22082996/testing-the-keychain-osstatus-error-34018
  //  instantiating the keychain via GCD can cause errors later when trying to add to the keychain
  if (sharedKeychain == nil) {
    sharedKeychain = [[self alloc] init];
    if(!sharedKeychain) {
      NYPLLOG(@"Failed to create shared keychain.");
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
  return [self objectForKey:key accessGroup:nil];
}

- (id)objectForKey:(NSString *const)key accessGroup:(NSString *const)groupID
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  dictionary[(__bridge __strong id) kSecMatchLimit] = (__bridge id) kSecMatchLimitOne;
  dictionary[(__bridge __strong id) kSecReturnData] = (__bridge id) kCFBooleanTrue;
  if (groupID) {
    dictionary[(__bridge __strong id) kSecAttrAccessGroup] = groupID;
  }
  
  CFTypeRef resultRef = NULL;
  SecItemCopyMatching((__bridge CFDictionaryRef) dictionary, &resultRef);
  
  NSData *const result = (__bridge_transfer NSData *) resultRef;
  if(!result) return nil;
  
  return [NSKeyedUnarchiver unarchiveObjectWithData:result];
}

- (void)setObject:(id)value forKey:(NSString *)key
{
  [self setObject:value forKey:key accessGroup:nil];
}

- (void)setObject:(id const)value forKey:(NSString *const)key accessGroup:(NSString *const)groupID
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  NSData *const valueData = [NSKeyedArchiver archivedDataWithRootObject:value];
  
  NSMutableDictionary *const queryDictionary = [self defaultDictionary];
  queryDictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  if (groupID) {
    queryDictionary[(__bridge __strong id) kSecAttrAccessGroup] = groupID;
  }

  OSStatus status;
  if([self objectForKey:key accessGroup:groupID]) {
    NSMutableDictionary *const updateDictionary = [NSMutableDictionary dictionary];
    updateDictionary[(__bridge __strong id) kSecValueData] = valueData;
    updateDictionary[(__bridge __strong id) kSecAttrAccessible] = (__bridge id _Nullable)(kSecAttrAccessibleAfterFirstUnlock);
    status = SecItemUpdate((__bridge CFDictionaryRef) queryDictionary,
                           (__bridge CFDictionaryRef) updateDictionary);
    if (status != noErr) {
      NYPLLOG_F(@"Failed to UPDATE secure values to keychain for group: %@. This is a known issue when running from the debugger. Error: %d", groupID, (int)status);
    }
  } else {
    NSMutableDictionary *const newItemDictionary = queryDictionary.mutableCopy;
    newItemDictionary[(__bridge __strong id) kSecValueData] = valueData;
    newItemDictionary[(__bridge __strong id) kSecAttrAccessible] = (__bridge id _Nullable)(kSecAttrAccessibleAfterFirstUnlock);
    status = SecItemAdd((__bridge CFDictionaryRef) newItemDictionary, NULL);
    if (status != noErr) {
      NYPLLOG_F(@"Failed to ADD secure values to keychain for group: %@. This is a known issue when running from the debugger. Error: %d", groupID, (int)status);
    }
  }
}

- (void)removeObjectForKey:(NSString *const)key
{
  [self removeObjectForKey:key accessGroup:nil];
}

- (void)removeObjectForKey:(NSString *const)key accessGroup:(NSString *const)groupID
{
  NSData *const keyData = [NSKeyedArchiver archivedDataWithRootObject:key];
  
  NSMutableDictionary *const dictionary = [self defaultDictionary];
  dictionary[(__bridge __strong id) kSecAttrAccount] = keyData;
  if (groupID) {
    dictionary[(__bridge __strong id) kSecAttrAccessGroup] = groupID;
  }
  
  OSStatus status = SecItemDelete((__bridge CFDictionaryRef) dictionary);
  if (status != noErr && status != errSecItemNotFound) {
    NYPLLOG_F(@"Failed to REMOVE object from keychain group: %@. error: %d", groupID, (int)status);
  }
}

@end
