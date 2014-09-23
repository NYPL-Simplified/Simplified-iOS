// This is an empty class acting as the shared superclass of all book cell classes. Its purpose is
// simply to encapsulate dequeueing cells from a UICollectionView so that the logic does not need to
// be repeated for every part of the application that displays book cells.

#import "NYPLMyBooksState.h"

@class NYPLBook;
@class NYPLBookCell;

@protocol NYPLBookNormalCellDelegate;
@protocol NYPLBookDownloadFailedCellDelegate;
@protocol NYPLBookDownloadingCellDelegate;

// This is exposed to help classes implement collection view layout delegates.
NSInteger NYPLBookCellColumnCountForCollectionViewWidth(CGFloat screenWidth);

// This is exposed to help classes implement collection view layout delegates.
CGSize NYPLBookCellSize(NSIndexPath *indexPath, CGFloat screenWidth);

// This should be called once after creating the collection view.
void NYPLBookCellRegisterClassesForCollectionView(UICollectionView *collectionView);

// The caller is responsible for unregistering all observers in the returned array.
NSArray *NYPLBookCellRegisterNotificationsForCollectionView(UICollectionView *collectionView);

// Returns an appropriate subclass of NYPLBookCell.
NYPLBookCell *NYPLBookCellDequeue(UICollectionView *collectionView,
                                  NSIndexPath *indexPath,
                                  NYPLBook *book);

@protocol NYPLBookCellDelegate
 <NYPLBookNormalCellDelegate, NYPLBookDownloadFailedCellDelegate, NYPLBookDownloadingCellDelegate>

@end

@interface NYPLBookCell : UICollectionViewCell

// Returns the frame of the content view frame minus the border, if present. Use this for laying
// out subviews rather than |contentView.frame|.
- (CGRect)contentFrame;

@end