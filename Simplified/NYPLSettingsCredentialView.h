typedef NS_ENUM(NSInteger, NYPLSettingsCredentialViewMessage) {
  NYPLSettingsCredentialViewMessageCardRequired,
  NYPLSettingsCredentialViewMessageCardOrPINInvalid
};

@interface NYPLSettingsCredentialView : UIView

- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
- (instancetype)init;

@end
