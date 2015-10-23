//
//  NYPLRegistrationStoryboard.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/23/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NYPLRegistrationStoryboard;

@protocol NYPLRegistrationStoryboardDelegate <NSObject>
- (void)storyboard:(NYPLRegistrationStoryboard *)storyboard willDismissWithNewAuthorization:(BOOL)hasNewAuthorization;
@end

@interface NYPLRegistrationStoryboard : UIStoryboard
@property (nonatomic, assign) id<NYPLRegistrationStoryboardDelegate> delegate;
@end
