//
//  NYPLIntroCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/15/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLIntroCardController.h"
#import "NYPLSettings.h"
#import "NYPLCardApplicationModel.h"

@interface NYPLIntroCardController ()
@property (nonatomic, assign) BOOL shouldShowContinuePrompt;
@end

@implementation NYPLIntroCardController

- (void) viewDidLoad
{
  [super viewDidLoad];
  self.shouldShowContinuePrompt = ([NYPLCardApplicationModel currentCardApplication] != nil);
}

- (IBAction)continuePressed:(__attribute__((unused)) id)sender
{
  if (self.shouldShowContinuePrompt) {
    self.shouldShowContinuePrompt = NO;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Continue?", nil)
                                                                             message:NSLocalizedString(@"It looks like you've got a card application already in progress", nil)
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(__attribute__((unused)) UIAlertAction * _Nonnull action) {
                                                        NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:self];
                                                        BOOL keepGoing = YES;
                                                        
                                                        if (keepGoing) {
                                                          keepGoing = self.currentApplication.dob != nil;
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"birthdate"]];
                                                        }
                                                        if (keepGoing) {
                                                          keepGoing = self.currentApplication.isInNYState == YES;
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"location"]];
                                                        }
                                                        if (keepGoing) {
                                                          keepGoing = self.currentApplication.photo != nil;
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"photo"]];
                                                        }
                                                        if (keepGoing) {
                                                          keepGoing = (self.currentApplication.firstName != nil) && (self.currentApplication.lastName != nil);
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"name"]];
                                                        }
                                                        if (keepGoing) {
                                                          keepGoing = self.currentApplication.address != nil;
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"address"]];
                                                        }
                                                        if (keepGoing) {
                                                          keepGoing = self.currentApplication.email != nil;
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"email"]];
                                                        }
                                                        if (keepGoing) {
                                                          [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:@"sending"]];
                                                        }
                                                        
                                                        [self.navigationController setViewControllers:viewControllers animated:YES];
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Start Over", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(__attribute__((unused)) UIAlertAction * _Nonnull action) {
                                                        [NYPLCardApplicationModel clearCurrentApplication];
                                                        self.currentApplication = [NYPLCardApplicationModel beginCardApplication];
                                                        [self performSegueWithIdentifier:@"birthdate" sender:self];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
  } else {
    if (self.currentApplication == nil)
      self.currentApplication = [NYPLCardApplicationModel beginCardApplication];
    [self performSegueWithIdentifier:@"birthdate" sender:self];
  }
}

@end
