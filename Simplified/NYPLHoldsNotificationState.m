//
//  NYPLHoldsNotificationState.m
//  SimplyE
//
//  Created by Vui Nguyen on 11/16/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

#import "NYPLHoldsNotificationState.h"
/*
NYPLHoldsNotificationState NYPLHoldsNotificationStateFromInt(NSUInteger holdsNotificationInt) {

}

NSUInteger NYPLHoldsNotificationStateToInt(NYPLHoldsNotificationState holdsNotificationState) {
  
}
*/

static NSString *const NotApplicable = @"not-applicable";
static NSString *const WaitingForAvailability = @"waiting-for-availability";
static NSString *const AvailableForCheckout = @"available-for-checkout";
static NSString *const FirstNotificationSent = @"first-notification-sent";
static NSString *const WaitForOneDayLeft = @"wait-for-one-day-left";
static NSString *const OneDayNotificationSent = @"one-day-notification-sent";

NYPLHoldsNotificationState NYPLHoldsNotificationStateFromString(NSString *string)
{
  if([string isEqualToString:NotApplicable]) return NYPLHoldsNotificationStateNotApplicable;
  if([string isEqualToString:WaitingForAvailability]) return NYPLHoldsNotificationStateWaitingForAvailability;
  if([string isEqualToString:AvailableForCheckout]) return NYPLHoldsNotificationStateAvailableForCheckout;
  if([string isEqualToString:FirstNotificationSent]) return NYPLHoldsNotificationStateFirstNotificationSent;
  if([string isEqualToString:WaitForOneDayLeft]) return NYPLHoldsNotificationStateWaitForOneDayLeft;
  if([string isEqualToString:OneDayNotificationSent]) return NYPLHoldsNotificationStateOneDayNotificationSent;

  @throw NSInvalidArgumentException;
}

NSString *NYPLHoldsNotificationStateToString(NYPLHoldsNotificationState state)
{
  switch(state) {
    case NYPLHoldsNotificationStateNotApplicable:
      return NotApplicable;
    case NYPLHoldsNotificationStateWaitingForAvailability:
      return WaitingForAvailability;
    case NYPLHoldsNotificationStateAvailableForCheckout:
      return AvailableForCheckout;
    case NYPLHoldsNotificationStateFirstNotificationSent:
      return FirstNotificationSent;
    case NYPLHoldsNotificationStateWaitForOneDayLeft:
      return WaitForOneDayLeft;
    case NYPLHoldsNotificationStateOneDayNotificationSent:
      return OneDayNotificationSent;
  }
}
