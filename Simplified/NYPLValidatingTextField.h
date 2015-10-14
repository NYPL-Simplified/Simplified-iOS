//
//  NYPLValidatingTextField.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NYPLValidatingTextField : UITextField
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, copy) BOOL (^validator)();

- (void) validate;
@end
