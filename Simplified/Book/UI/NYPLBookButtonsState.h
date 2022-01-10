//
//  NYPLBookButtonsState.h
//  Simplified
//
//  Created by Ettore Pasquini on 3/18/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, NYPLBookButtonsState) {
  NYPLBookButtonsStateCanBorrow,
  NYPLBookButtonsStateCanHold,
  NYPLBookButtonsStateHolding,
  NYPLBookButtonsStateHoldingFOQ, //Front Of Queue: a book that was Reserved and now it's Ready for borrow
  NYPLBookButtonsStateDownloadNeeded,
  NYPLBookButtonsStateDownloadSuccessful,
  NYPLBookButtonsStateUsed,
  NYPLBookButtonsStateDownloadInProgress,
  NYPLBookButtonsStateDownloadFailed,
  NYPLBookButtonsStateUnsupported
};

@protocol NYPLOPDSAcquisitionAvailability;

/// @param availability A non-nil @c NYPLOPDSAcquisitionAvailability.
/// @return A @c Borrow, @c Keep, @c Hold, @c Holding, or @c HoldingFOQ state.
NYPLBookButtonsState
NYPLBookButtonsViewStateWithAvailability(id<NYPLOPDSAcquisitionAvailability> availability);
