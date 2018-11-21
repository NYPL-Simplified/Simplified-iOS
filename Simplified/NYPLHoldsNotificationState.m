//
//  NYPLHoldsNotificationState.m
//  SimplyE
//
//  Created by Vui Nguyen on 11/16/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

#import "NYPLHoldsNotificationState.h"

static NSString *const NotApplicable = @"not-applicable";
static NSString *const ReadyForFirstNotification = @"ready-for-first-notification";
static NSString *const FirstNotificationSent = @"first-notification-sent";
static NSString *const ReadyForFinalNotification = @"ready-for-final-notification";
static NSString *const FinalNotificationSent = @"final-notification-sent";

NYPLHoldsNotificationState NYPLHoldsNotificationStateFromString(NSString *string)
{
  if([string isEqualToString:NotApplicable]) return NYPLHoldsNotificationStateNotApplicable;
  if([string isEqualToString:ReadyForFirstNotification]) return NYPLHoldsNotificationStateReadyForFirstNotification;
  if([string isEqualToString:FirstNotificationSent]) return NYPLHoldsNotificationStateFirstNotificationSent;
  if([string isEqualToString:ReadyForFinalNotification]) return NYPLHoldsNotificationStateReadyForFinalNotification;
  if([string isEqualToString:FinalNotificationSent]) return NYPLHoldsNotificationStateFinalNotificationSent;

  @throw NSInvalidArgumentException;
}

NSString *NYPLHoldsNotificationStateToString(NYPLHoldsNotificationState state)
{
  switch(state) {
    case NYPLHoldsNotificationStateNotApplicable:
      return NotApplicable;
    case NYPLHoldsNotificationStateReadyForFirstNotification:
      return ReadyForFirstNotification;
    case NYPLHoldsNotificationStateFirstNotificationSent:
      return FirstNotificationSent;
    case NYPLHoldsNotificationStateReadyForFinalNotification:
      return ReadyForFinalNotification;
    case NYPLHoldsNotificationStateFinalNotificationSent:
      return FinalNotificationSent;
  }
}
