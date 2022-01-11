//
//  NYPLProblemReportViewController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NYPLProblemReportViewController;
@class NYPLBook;

@protocol NYPLProblemReportViewControllerDelegate
- (void)problemReportViewController:(NYPLProblemReportViewController *)problemReportViewController didSelectProblemWithType:(NSString *)type;
@end

@interface NYPLProblemReportViewController : UIViewController
@property (nonatomic, strong) NYPLBook *book;
@property (nonatomic, weak) id<NYPLProblemReportViewControllerDelegate> delegate;
@end
