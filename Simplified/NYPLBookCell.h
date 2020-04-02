// This is an empty class acting as the shared superclass of all book cell classes. Its purpose is
// simply to encapsulate dequeueing cells from a UICollectionView so that the logic does not need to
// be repeated for every part of the application that displays book cells.

@class NYPLBook;
@class NYPLBookCell;

// This is exposed to help classes implement collection view layout delegates.
NSInteger NYPLBookCellColumnCountForCollectionViewWidth(CGFloat screenWidth);

// This is exposed to help classes implement collection view layout delegates.
CGSize NYPLBookCellSize(NSIndexPath *indexPath, CGFloat screenWidth);

// This should be called once after creating the collection view.
void NYPLBookCellRegisterClassesForCollectionView(UICollectionView *collectionView);

// Returns an appropriate subclass of NYPLBookCell.
NYPLBookCell *NYPLBookCellDequeue(UICollectionView *collectionView,
                                  NSIndexPath *indexPath,
                                  NYPLBook *book);

@interface NYPLBookCell : UICollectionViewCell

// Returns the frame of the content view frame minus the border, if present. Use this for laying
// out subviews rather than |contentView.frame|.
- (CGRect)contentFrame;

@end
