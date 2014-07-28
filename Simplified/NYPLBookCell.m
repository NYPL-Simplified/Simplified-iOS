#import "NYPLBookCellDelegate.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLBookCell.h"

@implementation NYPLBookCell

@end

static NSString *const reuseIdentifierDownloading = @"Downloading";
static NSString *const reuseIdentifierDownloadFailed = @"DownloadFailed";
static NSString *const reuseIdentifierNormal = @"Normal";

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
     addObserverForName:NYPLBookRegistryDidChange
     object:nil
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(__attribute__((unused)) NSNotification *note) {
       [collectionView reloadData];
     }];
  
  id observer2 =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:NYPLMyBooksDownloadCenterDidChange
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
  }
}