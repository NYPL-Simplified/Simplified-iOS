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

CGSize NYPLBookCellSize(UIUserInterfaceIdiom idiom,
                        UIInterfaceOrientation orientation,
                        NSIndexPath *indexPath)
{
  if(idiom == UIUserInterfaceIdiomPad) {
    switch(orientation) {
      case UIInterfaceOrientationPortrait:
        // fallthrough
      case UIInterfaceOrientationPortraitUpsideDown:
        return CGSizeMake(384, 110);
      case UIInterfaceOrientationLandscapeLeft:
        // fallthrough
      case UIInterfaceOrientationLandscapeRight:
        return CGSizeMake(341 + (indexPath.row % 3 == 1), 110);
    }
  } else {
    return CGSizeMake(320, 110);
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

NSArray *NYPLBookCellRegisterNotificationsForCollectionView(UICollectionView *const collectionView)
{
  id observer1 =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:NYPLBookRegistryDidChangeNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(__attribute__((unused)) NSNotification *note) {
       [collectionView reloadData];
     }];
  
  id observer2 =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:NYPLMyBooksDownloadCenterDidChangeNotification
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(__attribute__((unused)) NSNotification *note) {
       for(UICollectionViewCell *const cell in [collectionView visibleCells]) {
         if([cell isKindOfClass:[NYPLBookDownloadingCell class]]) {
           NYPLBookDownloadingCell *const downloadingCell = (NYPLBookDownloadingCell *)cell;
           NSString *const bookIdentifier = downloadingCell.book.identifier;
           downloadingCell.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                               downloadProgressForBookIdentifier:bookIdentifier];
         }
       }
     }];
  
  return @[observer1, observer2];
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