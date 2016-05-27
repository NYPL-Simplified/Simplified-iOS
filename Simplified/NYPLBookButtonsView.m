//
//  NYPLBookButtonsView.m
//  Simplified
//
//  Created by Ben Anderman on 8/27/15.
//  Copyright (c) 2015 NYPL Labs. All rights reserved.
//

#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookRegistry.h"
#import "NYPLBookButtonsView.h"
#import "NYPLRoundedButton.h"
#import "NYPLSettings.h"
#import "NYPLRootTabBarController.h"

@interface NYPLBookButtonsView ()

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) NYPLRoundedButton *readButton;
@property (nonatomic) NSArray *visibleButtons;
@property (nonatomic) id observer;

@end

@implementation NYPLBookButtonsView

- (instancetype)init
{
  self = [super init];
  if(!self) {
    return self;
  }
  
  self.deleteButton = [NYPLRoundedButton button];
  [self.deleteButton addTarget:self action:@selector(didSelectReturn) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.deleteButton];

  self.downloadButton = [NYPLRoundedButton button];
  [self.downloadButton addTarget:self action:@selector(didSelectDownload) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.downloadButton];

  self.readButton = [NYPLRoundedButton button];
  [self.readButton addTarget:self action:@selector(didSelectRead) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.readButton];
  
  self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicator.hidesWhenStopped = YES;
  [self addSubview:self.activityIndicator];
  
  self.observer = [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLBookProcessingDidChangeNotification
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(NSNotification *note) {
     if([note.userInfo[@"identifier"] isEqualToString:self.book.identifier]) {
       [self updateProcessingState];
     }
   }];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
}

- (void)updateButtonFrames
{
  NYPLRoundedButton *lastButton = nil;
  for (NYPLRoundedButton *button in self.visibleButtons) {
    [button sizeToFit];
    CGRect frame = button.frame;
    if (!lastButton) {
      frame.origin = CGPointZero;
    } else {
      frame.origin = CGPointMake(CGRectGetMaxX(lastButton.frame) + 5,
                                 CGRectGetMinY(lastButton.frame));
    }
    lastButton = button;
    button.frame = frame;
  }
  self.activityIndicator.center = CGPointMake(CGRectGetMaxX(lastButton.frame) + 5 + self.activityIndicator.frame.size.width / 2,
                                              lastButton.center.y);
}

- (void)sizeToFit
{
  NYPLRoundedButton *lastButton = [self.visibleButtons lastObject];
  CGRect frame = self.frame;
  frame.size = CGSizeMake(CGRectGetMaxX(lastButton.frame), CGRectGetMaxY(lastButton.frame));
  self.frame = frame;
}

- (void)updateProcessingState
{
  BOOL state = [[NYPLBookRegistry sharedRegistry] processingForIdentifier:self.book.identifier];
  if(state) {
    [self.activityIndicator startAnimating];
  } else {
    [self.activityIndicator stopAnimating];
  }
  for(NYPLRoundedButton *button in @[self.downloadButton, self.deleteButton, self.readButton]) {
    button.enabled = !state;
  }
}

- (void)updateButtons
{
  NSArray *visibleButtonInfo = nil;
  static NSString *const ButtonKey = @"button";
  static NSString *const TitleKey = @"title";
  static NSString *const HintKey = @"accessibilityHint";
  static NSString *const AddIndicatorKey = @"addIndicator";
  
  NSString *fulfillmentId = [[NYPLBookRegistry sharedRegistry] fulfillmentIdForIdentifier:self.book.identifier];
  
  switch(self.state) {
    case NYPLBookButtonsStateCanBorrow:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                              TitleKey: NSLocalizedString(@"Borrow", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Borrows %@", nil), self.book.title]}];
      break;
    case NYPLBookButtonsStateCanKeep:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                              TitleKey: NSLocalizedString(@"Download", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Downloads %@", nil), self.book.title]}];
      break;
    case NYPLBookButtonsStateCanHold:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                              TitleKey: NSLocalizedString(@"Reserve", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Holds %@", nil), self.book.title]}];
      break;
    case NYPLBookButtonsStateHolding:
      visibleButtonInfo = @[@{ButtonKey: self.deleteButton,
                              TitleKey: NSLocalizedString(@"Remove", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Cancels hold for %@", nil), self.book.title],
                              AddIndicatorKey: @(YES)}];
      break;
    case NYPLBookButtonsStateHoldingFOQ:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                              TitleKey: NSLocalizedString(@"Borrow", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Borrows %@", nil), self.book.title],
                              AddIndicatorKey: @(YES)},
                            @{ButtonKey: self.deleteButton,
                              TitleKey: NSLocalizedString(@"Remove", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Cancels hold for %@", nil), self.book.title]}];
      break;
    case NYPLBookButtonsStateDownloadNeeded:
    {
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                              TitleKey: NSLocalizedString(@"Download", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Downloads %@", nil), self.book.title],
                              AddIndicatorKey: @(YES)}];
        
      if (self.showReturnButtonIfApplicable)
      {
        NSString *title = self.book.acquisition.openAccess ? NSLocalizedString(@"Delete", nil) : NSLocalizedString(@"ReturnNow", nil);
        NSString *hint = self.book.acquisition.openAccess ? [NSString stringWithFormat:NSLocalizedString(@"Deletes %@", nil), self.book.title] : [NSString stringWithFormat:NSLocalizedString(@"Returns %@", nil), self.book.title];

        visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                                TitleKey: NSLocalizedString(@"Download", nil),
                                HintKey: [NSString stringWithFormat:NSLocalizedString(@"Downloads %@", nil), self.book.title],
                                AddIndicatorKey: @(YES)},
                              @{ButtonKey: self.deleteButton,
                                TitleKey: title,
                                HintKey: hint}];

      }
      break;
    }
    case NYPLBookButtonsStateDownloadSuccessful:
      // Fallthrough
    case NYPLBookButtonsStateUsed:
    {
      visibleButtonInfo = @[@{ButtonKey: self.readButton,
                              TitleKey: NSLocalizedString(@"Read", nil),
                              HintKey: [NSString stringWithFormat:NSLocalizedString(@"Opens %@ for reading", nil), self.book.title],
                              AddIndicatorKey: @(YES)}];
        
      if (self.showReturnButtonIfApplicable)
      {
        NSString *title = self.book.acquisition.openAccess ? NSLocalizedString(@"Delete", nil) : NSLocalizedString(@"ReturnNow", nil);\
        NSString *hint = self.book.acquisition.openAccess ? [NSString stringWithFormat:NSLocalizedString(@"Deletes %@", nil), self.book.title] : [NSString stringWithFormat:NSLocalizedString(@"Returns %@", nil), self.book.title];

        visibleButtonInfo = @[@{ButtonKey: self.readButton,
                                TitleKey: NSLocalizedString(@"Read", nil),
                                HintKey: [NSString stringWithFormat:NSLocalizedString(@"Opens %@ for reading", nil), self.book.title],
                                AddIndicatorKey: @(YES)},
                              @{ButtonKey: self.deleteButton,
                                TitleKey: title,
                                HintKey: hint}];

      }
      break;
    }
  }
  
  NSMutableArray *visibleButtons = [NSMutableArray array];
  
  BOOL fulfillmentIdRequired = NO;
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:self.book.identifier];
  BOOL hasRevokeLink = (self.book.acquisition.revoke && state & (NYPLBookStateDownloadSuccessful | NYPLBookStateUsed));

  #if defined(FEATURE_DRM_CONNECTOR)
  
  // It's required unless the book is being held and has a revoke link
  fulfillmentIdRequired = !(self.state == NYPLBookButtonsStateHolding && self.book.acquisition.revoke);
  
  #endif
  
  for (NSDictionary *buttonInfo in visibleButtonInfo) {
    NYPLRoundedButton *button = buttonInfo[ButtonKey];
    if(button == self.deleteButton && (!fulfillmentId && fulfillmentIdRequired) && !hasRevokeLink) {
      if(!self.book.acquisition.openAccess) {
        continue;
      }
    }
    button.hidden = NO;
    [button setTitle:buttonInfo[TitleKey] forState:UIControlStateNormal];
    if ([buttonInfo[AddIndicatorKey] isEqualToValue:@(YES)]) {
      if (self.book.availableUntil && [self.book.availableUntil timeIntervalSinceNow] > 0) {
        button.type = NYPLRoundedButtonTypeClock;
        button.endDate = self.book.availableUntil;
      } else {
        button.type = NYPLRoundedButtonTypeNormal;
        // We could handle queue support here if we wanted it.
        // button.type = NYPLRoundedButtonTypeQueue;
        // button.queuePosition = self.book.holdPosition;
      }
    } else {
      button.type = NYPLRoundedButtonTypeNormal;
    }
    [visibleButtons addObject:button];
  }
  for (NYPLRoundedButton *button in @[self.downloadButton, self.deleteButton, self.readButton]) {
    if (![visibleButtons containsObject:button]) {
      button.hidden = YES;
    }
  }
  self.visibleButtons = visibleButtons;
  [self updateButtonFrames];
}

- (void)setBook:(NYPLBook *)book
{
  _book = book;
  [self updateButtons];
  [self updateProcessingState];
}

- (void)setState:(NYPLBookButtonsState const)state
{
  _state = state;
  [self updateButtons];
}

#pragma mark - Button actions

- (void)didSelectReturn
{
  NSString *title = nil;
  NSString *message = nil;
  NSString *confirmButtonTitle = nil;
  
  switch([[NYPLBookRegistry sharedRegistry] stateForIdentifier:self.book.identifier]) {
    case NYPLBookStateUsed:
    case NYPLBookStateDownloading:
    case NYPLBookStateUnregistered:
    case NYPLBookStateDownloadFailed:
    case NYPLBookStateDownloadNeeded:
    case NYPLBookStateDownloadSuccessful:
      title = (self.book.acquisition.openAccess
               ? NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitle", nil)
               : NSLocalizedString(@"MyBooksDownloadCenterConfirmReturnTitle", nil));
      message = (self.book.acquisition.openAccess
                 ? NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitleMessageFormat", nil)
                 : NSLocalizedString(@"MyBooksDownloadCenterConfirmReturnTitleMessageFormat", nil));
      confirmButtonTitle = (self.book.acquisition.openAccess
                            ? NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitle", nil)
                            : NSLocalizedString(@"MyBooksDownloadCenterConfirmReturnTitle", nil));
      break;
    case NYPLBookStateHolding:
      title = NSLocalizedString(@"BookButtonsViewRemoveHoldTitle", nil);
      message = [NSString stringWithFormat:
                 NSLocalizedString(@"BookButtonsViewRemoveHoldMessage", nil),
                 self.book.title];
      confirmButtonTitle = NSLocalizedString(@"BookButtonsViewRemoveHoldConfirm", nil);
      break;
  }
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                           message:[NSString stringWithFormat:
                                                                                    message, self.book.title]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  
  [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
  
  [alertController addAction:[UIAlertAction actionWithTitle:confirmButtonTitle
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                                      [self.delegate didSelectReturnForBook:self.book];
                                                    }]];
  
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alertController animated:YES completion:nil];
}

- (void)didSelectRead
{
  [self.delegate didSelectReadForBook:self.book];
}

- (void)didSelectDownload
{
  [self.delegate didSelectDownloadForBook:self.book];
}

@end
