#import "NYPLBook.h"
#import "NYPLBookCellDelegate.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLBookCell.h"

static NSString *const reuseIdentifierDownloading = @"Downloading";
static NSString *const reuseIdentifierDownloadFailed = @"DownloadFailed";
static NSString *const reuseIdentifierNormal = @"Normal";

NSInteger NYPLBookCellColumnCountForCollectionViewWidth(CGFloat const collectionViewWidth)
{
  return collectionViewWidth / 320;
}

CGSize NYPLBookCellSize(NSIndexPath *const indexPath, CGFloat const collectionViewWidth)
{
  static CGFloat const height = 110;
  
  NSInteger const cellsPerRow = collectionViewWidth / 320;
  CGFloat const averageCellWidth = collectionViewWidth / (CGFloat)cellsPerRow;
  CGFloat const baseCellWidth = floor(averageCellWidth);
  
  if(indexPath.row % cellsPerRow == 0) {
    // Add the extra points to the first cell in each row.
    return CGSizeMake(collectionViewWidth - ((cellsPerRow - 1) * baseCellWidth), height);
  } else {
    return CGSizeMake(baseCellWidth, height);
  }
}

void NYPLBookCellRegisterClassesForCollectionView(UICollectionView *const collectionView)
{
  [collectionView registerClass:[NYPLBookDownloadFailedCell class]
     forCellWithReuseIdentifier:reuseIdentifierDownloadFailed];
  [collectionView registerClass:[NYPLBookDownloadingCell class]
     forCellWithReuseIdentifier:reuseIdentifierDownloading];
  [collectionView registerClass:[NYPLBookNormalCell class]
     forCellWithReuseIdentifier:reuseIdentifierNormal];
}

NYPLBookCell *NYPLBookCellDequeue(UICollectionView *const collectionView,
                                  NSIndexPath *const indexPath,
                                  NYPLBook *const book)
{
  NYPLMyBooksState const state = [[NYPLMyBooksRegistry sharedRegistry]
                                  stateForIdentifier:book.identifier];
  
  switch(state) {
    case NYPLMyBooksStateUnregistered:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookNormalCellStateUnregistered;
      return cell;
    }
    case NYPLMyBooksStateDownloadNeeded:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookNormalCellStateDownloadNeeded;
      return cell;
    }
    case NYPLMyBooksStateDownloadSuccessful:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookNormalCellStateDownloadSuccessful;
      return cell;
    }
    case NYPLMyBooksStateDownloading:
    {
      NYPLBookDownloadingCell *const cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierDownloading
                                                forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                               downloadProgressForBookIdentifier:book.identifier];
      return cell;
    }
    case NYPLMyBooksStateDownloadFailed:
    {
      NYPLBookDownloadFailedCell *const cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierDownloadFailed
                                                  forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      return cell;
    }
    case NYPLMYBooksStateUsed:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookNormalCellStateUsed;
      return cell;
    }
  }
}

@interface NYPLBookCell ()

@property (nonatomic) UIView *borderBottom;
@property (nonatomic) UIView *borderRight;

@end

@implementation NYPLBookCell

#pragma mark UIView

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // This is no longer set by default as of iOS 8.0.
    self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                         UIViewAutoresizingFlexibleWidth);
    
    {
      CGRect const frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 1,
                                      0,
                                      1,
                                      CGRectGetHeight(self.contentView.frame));
      self.borderRight = [[UIView alloc] initWithFrame:frame];
      self.borderRight.backgroundColor = [UIColor lightGrayColor];
      self.borderRight.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleHeight);
      [self.contentView addSubview:self.borderRight];
    }
    {
      CGRect const frame = CGRectMake(0,
                                      CGRectGetMaxY(self.contentView.frame) - 1,
                                      CGRectGetWidth(self.contentView.frame),
                                      1);
      self.borderBottom = [[UIView alloc] initWithFrame:frame];
      self.borderBottom.backgroundColor = [UIColor lightGrayColor];
      self.borderBottom.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleWidth);
      [self.contentView addSubview:self.borderBottom];
    }
  }
  
  return self;
}

#pragma mark -

- (CGRect)contentFrame
{
  CGRect frame = self.contentView.frame;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    frame.size.width = CGRectGetWidth(frame) - 1;
    frame.size.height = CGRectGetHeight(frame) - 1;
    return frame;
  } else {
    return frame;
  }
}

@end