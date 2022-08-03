#import "NYPLBook.h"
#import "NYPLBookCellDelegate.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLBookRegistry.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLOPDS.h"
#import "SimplyE-Swift.h"

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
  NYPLBookState const state = [[NYPLBookRegistry sharedRegistry]
                               stateForIdentifier:book.identifier];
  
  switch(state) {
    case NYPLBookStateUnregistered:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsViewStateWithAvailability(book.defaultAcquisition.availability);

      return cell;
    }
    case NYPLBookStateDownloadNeeded:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsStateDownloadNeeded;
      return cell;
    }
    case NYPLBookStateDownloadSuccessful:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsStateDownloadSuccessful;
      return cell;
    }
    // SAML started is part of download process, in this step app does authenticate user but didn't begin file downloading yet
    // The cell should present progress bar and "Requesting" description on its side
    case NYPLBookStateSAMLStarted:
    case NYPLBookStateDownloadingUsable:
    case NYPLBookStateDownloading:
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
    case NYPLBookStateDownloadFailed:
    {
      NYPLBookDownloadFailedCell *const cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifierDownloadFailed
                                                  forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      return cell;
    }
    case NYPLBookStateHolding:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsViewStateWithAvailability(book.defaultAcquisition.availability);

      return cell;
    }
    case NYPLBookStateUsed:
    {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsStateUsed;
      return cell;
    }
    case NYPLBookStateUnsupported: {
      NYPLBookNormalCell *const cell = [collectionView
                                        dequeueReusableCellWithReuseIdentifier:reuseIdentifierNormal
                                        forIndexPath:indexPath];
      cell.book = book;
      cell.delegate = [NYPLBookCellDelegate sharedDelegate];
      cell.state = NYPLBookButtonsStateUnsupported;
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
  
  if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {

    // This is no longer set by default as of iOS 8.0.
    self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                         UIViewAutoresizingFlexibleWidth);
    
    {
      CGRect const frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 1,
                                      0,
                                      1,
                                      CGRectGetHeight(self.contentView.frame));
      self.borderRight = [[UIView alloc] initWithFrame:frame];
      self.borderRight.backgroundColor = [NYPLConfiguration fieldBorderColor];
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
      self.borderBottom.backgroundColor = [NYPLConfiguration fieldBorderColor];
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
  
  if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    frame.size.width = CGRectGetWidth(frame) - 1;
    frame.size.height = CGRectGetHeight(frame) - 1;
    return frame;
  } else {
    return frame;
  }
}

@end
