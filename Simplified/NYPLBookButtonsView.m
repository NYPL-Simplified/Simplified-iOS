//
//  NYPLBookButtonsView.m
//  Simplified
//
//  Created by Ben Anderman on 8/27/15.
//  Copyright (c) 2015 NYPL Labs. All rights reserved.
//

#import "NYPLBookButtonsView.h"
#import "NYPLRoundedButton.h"
#import "NYPLBook.h"

@interface NYPLBookButtonsView ()

@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) NYPLRoundedButton *readButton;
@property (nonatomic) NSArray *visibleButtons;

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
  
  return self;
}

- (void)updateButtons
{
  NYPLRoundedButton *lastButton = nil;
  for (NYPLRoundedButton *button in self.visibleButtons) {
    [button sizeToFit];
    CGRect frame = button.frame;
    if (!lastButton) {
      lastButton = button;
      frame.origin = CGPointZero;
    } else {
      frame.origin = CGPointMake(CGRectGetMaxX(lastButton.frame) + 5,
                                 CGRectGetMinY(lastButton.frame));
    }
    button.frame = frame;
  }
}

- (void)sizeToFit
{
  NYPLRoundedButton *lastButton = [self.visibleButtons lastObject];
  CGRect frame = self.frame;
  frame.size = CGSizeMake(CGRectGetMaxX(lastButton.frame), CGRectGetMaxY(lastButton.frame));
  self.frame = frame;
}

- (void)setState:(NYPLBookButtonsState const)state
{
  _state = state;
  
  NSArray *visibleButtonInfo = nil;
  static NSString *const ButtonKey = @"button";
  static NSString *const TitleKey = @"title";
  static NSString *const AddIndicatorKey = @"addIndicator";
  
  switch(state) {
    case NYPLBookButtonsStateCanBorrow:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Borrow"}];
      break;
    case NYPLBookButtonsStateCanKeep:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Download"}];
      break;
    case NYPLBookButtonsStateCanHold:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Hold"}];
      break;
    case NYPLBookButtonsStateHolding:
      visibleButtonInfo = @[@{ButtonKey: self.deleteButton,   TitleKey: @"CancelHold", AddIndicatorKey: @(YES)}];
      break;
    case NYPLBookButtonsStateHoldingFOQ:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Borrow", AddIndicatorKey: @(YES)},
                            @{ButtonKey: self.deleteButton,   TitleKey: @"CancelHold"}];
      break;
    case NYPLBookButtonsStateDownloadNeeded:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Download"},
                            @{ButtonKey: self.deleteButton,   TitleKey: @"ReturnNow", AddIndicatorKey: @(YES)}];
      break;
    case NYPLBookButtonsStateDownloadSuccessful:
      // Fallthrough
    case NYPLBookButtonsStateUsed:
      visibleButtonInfo = @[@{ButtonKey: self.readButton,     TitleKey: @"Read"},
                            @{ButtonKey: self.deleteButton,   TitleKey: @"ReturnNow", AddIndicatorKey: @(YES)}];
      break;
  }
  
  NSMutableArray *visibleButtons = [NSMutableArray array];
  for (NSDictionary *buttonInfo in visibleButtonInfo) {
    NYPLRoundedButton *button = buttonInfo[ButtonKey];
    button.hidden = NO;
    [button setTitle:NSLocalizedString(buttonInfo[TitleKey], nil) forState:UIControlStateNormal];
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
  [self updateButtons];
}

#pragma mark - Button actions

- (void)didSelectReturn
{
  [self.delegate didSelectReturnForBook:self.book];
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
