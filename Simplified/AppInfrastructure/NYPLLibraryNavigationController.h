//
//  NYPLLibraryNavigationController.h
//  Simplified
//
//  Created by Ettore Pasquini on 9/18/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Account;

@interface NYPLLibraryNavigationController : UINavigationController

#ifdef SIMPLYE
- (void)setNavigationLeftBarButtonForVC:(UIViewController *)vc;
- (void)switchLibrary;
- (void)updateCatalogFeedSettingCurrentAccount:(Account *)account;
#endif

@end

