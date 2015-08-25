@import UIKit;

@interface NYPLAlertView : UIAlertView

+ (instancetype)alertWithTitle:(NSString *)title error:(NSError *)error;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message, ...;

@end
