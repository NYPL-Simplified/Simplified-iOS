// This class exists to have the handling of buttons for managing a book all in one place,
// because it's always identical, and used in at least book cells and book detail views.

@class NYPLBook;

@protocol NYPLOPDSAcquisitionAvailability;

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

/// @param availability A non-nil @c NYPLOPDSAcquisitionAvailability.
/// @return A @c Borrow, @c Keep, @c Hold, @c Holding, or @c HoldingFOQ state.
NYPLBookButtonsState NYPLBookButtonsViewStateWithAvailability(id<NYPLOPDSAcquisitionAvailability> availability);

@protocol NYPLBookButtonsDelegate

- (void)didSelectReturnForBook:(NYPLBook *)book;
- (void)didSelectDownloadForBook:(NYPLBook *)book;
- (void)didSelectReadForBook:(NYPLBook *)book;

@end

@interface NYPLBookButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;
/// return button flag, default value is NO. for example show return buttons if applicable in book detail view, but do not show return buttons in list views 
@property (nonatomic) BOOL showReturnButtonIfApplicable;

@end
