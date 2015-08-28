// This class exists to have the handling of buttons for managing a book all in one place,
// because it's always identical, and used in at least book cells and book detail views.

@class NYPLBook;

typedef NS_ENUM(NSInteger, NYPLBookButtonsState) {
  NYPLBookButtonsStateCanBorrow,
  NYPLBookButtonsStateCanKeep,
  NYPLBookButtonsStateCanHold,
  NYPLBookButtonsStateHolding,
  NYPLBookButtonsStateHoldingFOQ, // Front Of Queue
  NYPLBookButtonsStateDownloadNeeded,
  NYPLBookButtonsStateDownloadSuccessful,
  NYPLBookButtonsStateUsed
};

@protocol NYPLBookButtonsDelegate

- (void)didSelectReturnForBook:(NYPLBook *)book;
- (void)didSelectDownloadForBook:(NYPLBook *)book;
- (void)didSelectReadForBook:(NYPLBook *)book;

@end

@interface NYPLBookButtonsView : UIView

@property (nonatomic, weak) NYPLBook *book;
@property (nonatomic) NYPLBookButtonsState state;
@property (nonatomic, weak) id<NYPLBookButtonsDelegate> delegate;

@end
