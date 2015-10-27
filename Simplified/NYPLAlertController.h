//
//  NYPLAlertController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/27/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NYPLAlertController : UIAlertController
+ (instancetype)alertWithTitle:(NSString *)title error:(NSError *)error;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message, ...;
+ (instancetype)alertWithProblemDocumentData:(NSData *)data;
@end
