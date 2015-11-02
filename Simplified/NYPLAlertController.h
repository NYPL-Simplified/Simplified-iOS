//
//  NYPLAlertController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/27/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NYPLProblemDocument;

@interface NYPLAlertController : UIAlertController
+ (instancetype)alertWithTitle:(NSString *)title error:(NSError *)error;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message, ...;

- (void)setProblemDocument:(NYPLProblemDocument *)document displayDocumentMessage:(BOOL)yn;
- (void)presentFromViewControllerOrNil:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;
@end
