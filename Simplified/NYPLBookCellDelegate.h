#import "NYPLBookNormalCell.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookButtonsView.h"
#import "NYPLProblemReportViewController.h"

/* This class implements a shared delegate that performs all of its duties via the shared registry,
shared cover registry, shared download center, et cetera. */
@interface NYPLBookCellDelegate : NSObject
  <NYPLBookButtonsDelegate, NYPLBookDownloadFailedCellDelegate, NYPLBookDownloadingCellDelegate, NYPLProblemReportViewControllerDelegate>

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedDelegate;

@end
