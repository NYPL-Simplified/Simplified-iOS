//
//  NYPLProblemReportViewController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NYPLProblemReportViewController;

@protocol NYPLProblemReportViewControllerDelegate
- (void)problemReportViewController:(NYPLProblemReportViewController *)problemReportViewController didSelectProblemWithType:(NSString *)type;
@end

@interface NYPLProblemReportViewController : UIViewController
@property (nonatomic, weak) id<NYPLProblemReportViewControllerDelegate> delegate;
@end
