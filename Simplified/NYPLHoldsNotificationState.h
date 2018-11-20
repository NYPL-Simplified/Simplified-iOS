//
//  NYPLHoldsNotificationState.h
//  Simplified
//
//  Created by Vui Nguyen on 11/16/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//


typedef NS_ENUM(NSInteger, NYPLHoldsNotificationState) {
  NYPLHoldsNotificationStateNotApplicable,
  NYPLHoldsNotificationStateWaitingForAvailability,
  NYPLHoldsNotificationStateAvailableForCheckout,
  NYPLHoldsNotificationStateFirstNotificationSent,
  NYPLHoldsNotificationStateWaitForOneDayLeft,
  NYPLHoldsNotificationStateOneDayNotificationSent
};
 
/*
NYPLHoldsNotificationState NYPLHoldsNotificationStateFromInt(NSUInteger holdsNotificationInt);

NSUInteger NYPLHoldsNotificationStateToInt(NYPLHoldsNotificationState holdsNotificationState);
*/
NYPLHoldsNotificationState NYPLHoldsNotificationStateFromString(NSString *holdsNotificationString);

NSString *NYPLHoldsNotificationStateToString(NYPLHoldsNotificationState holdsNotificationState);
