//
//  NYPLBookButtonsState.m
//  Simplified
//
//  Created by Ettore Pasquini on 3/18/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

#import "NYPLBookButtonsState.h"
#import "NYPLOPDSAcquisitionAvailability.h"
#import "SimplyE-Swift.h"

NYPLBookButtonsState
NYPLBookButtonsViewStateWithAvailability(id<NYPLOPDSAcquisitionAvailability> const availability)
{
  __block NYPLBookButtonsState state = NYPLBookButtonsStateUnsupported;

  if (!availability) {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                              summary:@"Unable to determine BookButtonsViewState because no Availability was provided"
                             metadata:nil];
  }

  [availability
   matchUnavailable:^(__unused NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable) {
    state = NYPLBookButtonsStateCanHold;
  }
   limited:^(__unused NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited) {
    state = NYPLBookButtonsStateCanBorrow;
  }
   unlimited:^(__unused NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited) {
    state = NYPLBookButtonsStateCanBorrow;
  }
   reserved:^(__unused NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved) {
    state = NYPLBookButtonsStateHolding;
  }
   ready:^(__unused NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready) {
    state = NYPLBookButtonsStateHoldingFOQ;
  }];

  return state;
}
