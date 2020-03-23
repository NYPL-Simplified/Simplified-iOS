#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLBookDetailButtonsView.h"
#import "NYPLConfiguration.h"
#import "NYPLRoundedButton.h"

#import "NYPLRootTabBarController.h"
#import "NYPLOPDS.h"
#import <PureLayout/PureLayout.h>
#import "SimplyE-Swift.h"

@interface NYPLBookDetailButtonsView ()

@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) NYPLRoundedButton *readButton;
@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) NSArray *visibleButtons;
@property (nonatomic) NSMutableArray *constraints;
@property (nonatomic) id observer;

@end

@implementation NYPLBookDetailButtonsView

- (instancetype)init
{
  self = [super init];
  if(!self) {
    return self;
  }
  
  self.constraints = [[NSMutableArray alloc] init];
  
  self.deleteButton = [NYPLRoundedButton button];
  self.deleteButton.fromDetailView = YES;
  self.deleteButton.titleLabel.minimumScaleFactor = 0.8f;
  [self.deleteButton addTarget:self action:@selector(didSelectReturn) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.deleteButton];

  self.downloadButton = [NYPLRoundedButton button];
  self.downloadButton.fromDetailView = YES;
  self.downloadButton.titleLabel.minimumScaleFactor = 0.8f;
  [self.downloadButton addTarget:self action:@selector(didSelectDownload) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.downloadButton];

  self.readButton = [NYPLRoundedButton button];
  self.readButton.fromDetailView = YES;
  self.readButton.titleLabel.minimumScaleFactor = 0.8f;
  [self.readButton addTarget:self action:@selector(didSelectRead) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.readButton];
  
  self.cancelButton = [NYPLRoundedButton button];
  self.cancelButton.fromDetailView = YES;
  self.cancelButton.titleLabel.minimumScaleFactor = 0.8f;
  [self.cancelButton addTarget:self action:@selector(didSelectCancel) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.cancelButton];
  
  self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicator.color = [NYPLConfiguration mainColor];
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
  [NSLayoutConstraint deactivateConstraints:self.constraints];

  if (self.visibleButtons.count == 0) {
    return;
  }
  
  [self.constraints removeAllObjects];
  int count = 0;
  NYPLRoundedButton *lastButton = nil;
  for (NYPLRoundedButton *button in self.visibleButtons) {
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeTop]];
    [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeBottom]];
    if (!lastButton) {
      [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeLeading]];
    } else {
      [self.constraints addObject:[button autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:lastButton withOffset:6.0]];
    }
    if (count == (int)self.visibleButtons.count - 1) {
      [self.constraints addObject:[button autoPinEdgeToSuperviewEdge:ALEdgeTrailing]];
    }
    lastButton = button;
    count++;
  }
}

- (void)updateProcessingState
{
  BOOL state = [[NYPLBookRegistry sharedRegistry] processingForIdentifier:self.book.identifier];
  if(state) {
    [self.activityIndicator startAnimating];
  } else {
    [self.activityIndicator stopAnimating];
  }
  for(NYPLRoundedButton *button in @[self.downloadButton, self.deleteButton, self.readButton, self.cancelButton]) {
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
        NSString *title = (self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth) ? NSLocalizedString(@"Delete", nil) : NSLocalizedString(@"Return", nil);
        NSString *hint = (self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth) ? [NSString stringWithFormat:NSLocalizedString(@"Deletes %@", nil), self.book.title] : [NSString stringWithFormat:NSLocalizedString(@"Returns %@", nil), self.book.title];

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
      NSDictionary *buttonInfo;
      switch (self.book.defaultBookContentType) {
        case NYPLBookContentTypeAudiobook:
          buttonInfo = @{ButtonKey: self.readButton,
                         TitleKey: NSLocalizedString(@"Listen", nil),
                         HintKey: [NSString stringWithFormat:NSLocalizedString(@"Opens audiobook %@ for listening", nil), self.book.title],
                         AddIndicatorKey: @(YES)};
          break;
        case NYPLBookContentTypePDF:
        case NYPLBookContentTypeEPUB:
          buttonInfo = @{ButtonKey: self.readButton,
                         TitleKey: NSLocalizedString(@"Read", nil),
                         HintKey: [NSString stringWithFormat:NSLocalizedString(@"Opens %@ for reading", nil), self.book.title],
                         AddIndicatorKey: @(YES)};
          break;
        case NYPLBookContentTypeUnsupported:
          @throw NSInternalInconsistencyException;
          break;
      }

      visibleButtonInfo = @[buttonInfo];
        
      if (self.showReturnButtonIfApplicable)
      {
        NSString *title = (self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth) ? NSLocalizedString(@"Delete", nil) : NSLocalizedString(@"Return", nil);
        NSString *hint = (self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth) ? [NSString stringWithFormat:NSLocalizedString(@"Deletes %@", nil), self.book.title] : [NSString stringWithFormat:NSLocalizedString(@"Returns %@", nil), self.book.title];

        visibleButtonInfo = @[buttonInfo,
                              @{ButtonKey: self.deleteButton,
                                TitleKey: title,
                                HintKey: hint}];
      }
      break;
    }
    case NYPLBookButtonsStateDownloadInProgress:
    {
      if (self.showReturnButtonIfApplicable)
      {
        visibleButtonInfo = @[@{ButtonKey: self.cancelButton,
                                TitleKey: NSLocalizedString(@"Cancel", nil),
                                HintKey: [NSString stringWithFormat:NSLocalizedString(@"Cancels the download for the current book: %@", nil), self.book.title],
                                AddIndicatorKey: @(NO)}];
      }
      break;
    }
    case NYPLBookButtonsStateDownloadFailed:
    {
      if (self.showReturnButtonIfApplicable)
      {
        visibleButtonInfo = @[@{ButtonKey: self.downloadButton,
                                TitleKey: NSLocalizedString(@"Retry", nil),
                                HintKey: [NSString stringWithFormat:NSLocalizedString(@"Retry the failed download for this book: %@", nil), self.book.title],
                                AddIndicatorKey: @(NO)},
                              @{ButtonKey: self.cancelButton,
                                TitleKey: NSLocalizedString(@"Cancel", nil),
                                HintKey: [NSString stringWithFormat:NSLocalizedString(@"Cancels the failed download for this book: %@", nil), self.book.title],
                                AddIndicatorKey: @(NO)}];
      }
      break;
    }
    case NYPLBookButtonsStateUnsupported:
      // The app should never show books it cannot support, but if it mistakenly does,
      // no actions will be available.
      visibleButtonInfo = @[];
      break;
  }

  NSMutableArray *visibleButtons = [NSMutableArray array];
  
  BOOL fulfillmentIdRequired = NO;
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:self.book.identifier];
  BOOL hasRevokeLink = (self.book.revokeURL && state && (state == NYPLBookStateDownloadSuccessful || state == NYPLBookStateUsed));

  #if defined(FEATURE_DRM_CONNECTOR)
  
  // It's required unless the book is being held and has a revoke link
  fulfillmentIdRequired = !(self.state == NYPLBookButtonsStateHolding && self.book.revokeURL);
  
  #endif
  
  for (NSDictionary *buttonInfo in visibleButtonInfo) {
    NYPLRoundedButton *button = buttonInfo[ButtonKey];
    if(button == self.deleteButton && (!fulfillmentId && fulfillmentIdRequired) && !hasRevokeLink) {
      if(!self.book.defaultAcquisitionIfOpenAccess && [[AccountsManager sharedInstance] currentAccount].details.needsAuth) {
        continue;
      }
    }
    
    button.hidden = NO;
    
    // Disable the animation for changing the title. This helps avoid visual issues with
    // reloading data in collection views.
    [UIView setAnimationsEnabled:NO];
    
    [button setTitle:buttonInfo[TitleKey] forState:UIControlStateNormal];
    [button setAccessibilityHint:buttonInfo[HintKey]];

    // We need to lay things out here else animations will be back on before it happens.
    [button layoutIfNeeded];
    
    // Re-enable animations as per usual.
    [UIView setAnimationsEnabled:YES];

    // Provide End-Date for checked out loans
    if ([buttonInfo[AddIndicatorKey] isEqualToValue:@(YES)]) {
      if (self.book.defaultAcquisition.availability.until && [self.book.defaultAcquisition.availability.until timeIntervalSinceNow] > 0 && self.state != NYPLBookButtonsStateHolding) {
        button.type = NYPLRoundedButtonTypeClock;
        button.endDate = self.book.defaultAcquisition.availability.until;
      } else {
        button.type = NYPLRoundedButtonTypeNormal;
      }
    } else {
      button.type = NYPLRoundedButtonTypeNormal;
    }
    
    [visibleButtons addObject:button];
  }
  for (NYPLRoundedButton *button in @[self.downloadButton, self.deleteButton, self.readButton, self.cancelButton]) {
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
  self.activityIndicator.center = self.deleteButton.center;
  
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
      title = ((self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth)
               ? NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitle", nil)
               : NSLocalizedString(@"MyBooksDownloadCenterConfirmReturnTitle", nil));
      message = ((self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth)
                 ? NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitleMessageFormat", nil)
                 : NSLocalizedString(@"MyBooksDownloadCenterConfirmReturnTitleMessageFormat", nil));
      confirmButtonTitle = ((self.book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth)
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
    case NYPLBookStateUnsupported:
      @throw NSInternalInconsistencyException;
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
  self.activityIndicator.center = self.readButton.center;
  [self.delegate didSelectReadForBook:self.book];
}

- (void)didSelectDownload
{
  if (@available (iOS 10.0, *)) {
    if (self.state == NYPLBookButtonsStateCanHold) {
      [NYPLUserNotifications requestAuthorization];
    }
  }
  self.activityIndicator.center = self.downloadButton.center;
  [self.delegate didSelectDownloadForBook:self.book];
}

- (void)didSelectCancel
{
  switch([[NYPLBookRegistry sharedRegistry] stateForIdentifier:self.book.identifier]) {
    case NYPLBookStateDownloading: {
      [self.downloadingDelegate didSelectCancelForBookDetailDownloadingView:self];
      break;
    }
    case NYPLBookStateDownloadFailed: {
      [self.downloadingDelegate didSelectCancelForBookDetailDownloadFailedView:self];
      break;
    }
    default:
      break;
  }
  
}

@end
