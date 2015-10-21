//
//  NYPLSubmittingViewController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/21/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"

@class NYPLSubmittingViewController;

@protocol NYPLSubmittingViewControllerDelegate <NSObject>
- (void)submittingViewControllerDidReturnToCatalog:(NYPLSubmittingViewController *)vc;
- (void)submittingViewControllerDidCancel:(NYPLSubmittingViewController *)vc;
@end

@interface NYPLSubmittingViewController : NYPLCardApplicationViewController
@property (nonatomic, assign) id<NYPLSubmittingViewControllerDelegate> delegate;
- (IBAction)returnToCatalog:(id)sender;
- (IBAction)cancel:(id)sender;
@end
