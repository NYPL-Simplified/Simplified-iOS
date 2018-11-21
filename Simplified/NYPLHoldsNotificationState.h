//
//  NYPLHoldsNotificationState.h
//  Simplified
//
//  Created by Vui Nguyen on 11/16/18.
//  Copyright © 2018 NYPL Labs. All rights reserved.
//

typedef NS_ENUM(NSInteger, NYPLHoldsNotificationState) {
  NYPLHoldsNotificationStateNotApplicable,
  NYPLHoldsNotificationStateReadyForFirstNotification,
  NYPLHoldsNotificationStateFirstNotificationSent,
  NYPLHoldsNotificationStateReadyForFinalNotification,
  NYPLHoldsNotificationStateFinalNotificationSent
};

NYPLHoldsNotificationState NYPLHoldsNotificationStateFromString(NSString *holdsNotificationString);

NSString *NYPLHoldsNotificationStateToString(NYPLHoldsNotificationState holdsNotificationState);
