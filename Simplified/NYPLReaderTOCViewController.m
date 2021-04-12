#import <PureLayout/PureLayout.h>

#import "NYPLConfiguration.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReaderTOCViewController.h"
#import "SimplyE-Swift.h"

// Deprecated: this is used only by R1. R2 uses NYPLReaderPositionsVC.
@interface NYPLReaderTOCViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UILabel *noBookmarksLabel;
@property (nonatomic) UIRefreshControl *refreshControl;

- (IBAction)didSelectSegment:(id)sender;

@end

static NSString *const reuseIDTOC = @"contentCell";
static NSString *const reuseIDBookmark = @"bookmarkCell";

typedef NS_ENUM(NSInteger, SegmentControlType) {
  SegmentControlTypeTOC,
  SegmentControlTypeBookmark
};

static SegmentControlType
segmentControlTypeWithInteger(NSInteger const integer)
{
  if (integer < 0 || integer >= 2) {
    @throw NSInvalidArgumentException;
  }
  
  return integer;
}

// TODO: SIMPLY-2608
// Once bookmarks logic is finalized, it should be possible to refactor (and
// possibly even completely remove) this VC and related storyboard with
// NYPLReaderPositionsVC.
@implementation NYPLReaderTOCViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  self.title = NSLocalizedString(@"ReaderTOCViewControllerTitle", nil);
  
  [self createViews];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
  self.navigationController.navigationBar.translucent = YES;
  self.navigationController.navigationBar.barTintColor = nil;
  
  self.tableView.separatorColor = [UIColor grayColor];

  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      if ([self.tableView.subviews containsObject:self.refreshControl]){
        [self.refreshControl removeFromSuperview];
      }
      break;
    case SegmentControlTypeBookmark:
      if ([NYPLAnnotations syncIsPossibleAndPermitted]) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(userDidRefresh:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
      }
      break;
  }

  NYPLReaderSettings *readerSettings = [NYPLReaderSettings sharedSettings];
  self.view.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  self.tableView.backgroundColor = self.view.backgroundColor;
  self.noBookmarksLabel.textColor = readerSettings.foregroundColor;

  if (@available(iOS 13.0, *)) {
    self.segmentedControl.selectedSegmentTintColor = readerSettings.tintColor;
    [self.segmentedControl setTitleTextAttributes:@{ NSForegroundColorAttributeName : readerSettings.tintColor} forState:UIControlStateNormal];
    [self.segmentedControl setTitleTextAttributes:@{ NSForegroundColorAttributeName : readerSettings.selectedForegroundColor} forState:UIControlStateSelected];
  } else {
    self.segmentedControl.tintColor = readerSettings.tintColor;
  }

  [self.tableView reloadData];
}

- (void)userDidRefresh:(UIRefreshControl *)refreshControl
{
  __weak NYPLReaderTOCViewController *const weakSelf = self;

  [self.delegate
   TOCViewController:self
   didRequestSyncBookmarksWithCompletion:^(BOOL __unused success, NSArray<NYPLReadiumBookmark *> *bookmarks) {
     dispatch_async(dispatch_get_main_queue(), ^{
       weakSelf.bookmarks = bookmarks.mutableCopy;
       [weakSelf.tableView reloadData];
       [refreshControl endRefreshing];
       if (!success) {
         [weakSelf showAlertForFailedSync];
       }
     });
   }];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  NSUInteger numRows = 0;
  
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      numRows = self.tableOfContents.count;
      break;
    case SegmentControlTypeBookmark:
      numRows = self.bookmarks.count;
      break;
  }
  
  return numRows;
}

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:{
      NYPLReaderTOCCell *cell = [self.tableView
                                 dequeueReusableCellWithIdentifier:reuseIDTOC
                                 forIndexPath:indexPath];

      NYPLReaderTOCElement *const tocElement = self.tableOfContents[indexPath.row];
      BOOL isCurrentChapter = [self.currentChapter isEqualToString:tocElement.title];
      [cell configWithTitle:tocElement.title
               nestingLevel:tocElement.nestingLevel
        isForCurrentChapter:isCurrentChapter];
  
      return cell;
    }
    case SegmentControlTypeBookmark: {
      NYPLReaderBookmarkCell *cell = [self.tableView
                                      dequeueReusableCellWithIdentifier:reuseIDBookmark
                                      forIndexPath:indexPath];
      NYPLReadiumBookmark *const bookmark = self.bookmarks[indexPath.row];
      if (bookmark != nil) {
        [cell configWithChapterName:bookmark.chapter ?: @""
                   percentInChapter:bookmark.percentInChapter
                  rfc3339DateString:bookmark.timestamp];
      }

      return cell;
    }
  }
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *const)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:{
      NYPLReaderTOCElement *const TOCElement = self.tableOfContents[indexPath.row];
      [self.delegate TOCViewController:self
               didSelectOpaqueLocation:TOCElement.opaqueLocation];
      break;
    }
    case SegmentControlTypeBookmark:{
      NYPLReadiumBookmark *const bookmark = self.bookmarks[indexPath.row];
      [self.delegate TOCViewController:self didSelectBookmark:bookmark];
      break;
    }
  }
}

-(CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView estimatedHeightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      return [NYPLConfiguration defaultTOCRowHeight];
    case SegmentControlTypeBookmark:
      return [NYPLConfiguration defaultBookmarkRowHeight];
  }
}

-(CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      /* fallthrough */
    case SegmentControlTypeBookmark:
      return UITableViewAutomaticDimension;
  }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)__unused tableView editingStyleForRowAtIndexPath:(NSIndexPath *)__unused indexPath {
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      return UITableViewCellEditingStyleNone;
    case SegmentControlTypeBookmark:
      return UITableViewCellEditingStyleDelete;
  }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    if ((NSUInteger)indexPath.row < self.bookmarks.count) {
      NYPLReadiumBookmark *bookmark = self.bookmarks[indexPath.row];
      [self.bookmarks removeObjectAtIndex:indexPath.row];
      [self.delegate TOCViewController:self didDeleteBookmark:bookmark];
    }
    
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationFade)];
  }
}

- (IBAction)didSelectSegment:(UISegmentedControl *)__unused sender
{
  [self.tableView reloadData];
  switch (segmentControlTypeWithInteger(self.segmentedControl.selectedSegmentIndex)) {
    case SegmentControlTypeTOC:
      if ([self.tableView.subviews containsObject:self.refreshControl]){
        [self.refreshControl removeFromSuperview];
      }
      if (self.tableView.isHidden) {
        self.tableView.hidden = NO;
      }
      break;
    case SegmentControlTypeBookmark:
      if (self.bookmarks.count == 0 || self.bookmarks == nil) {
        self.tableView.hidden = YES;
      }
      if ([NYPLAnnotations syncIsPossibleAndPermitted]) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(userDidRefresh:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
      }
      break;
  }
}

#pragma mark -

- (void)createViews
{
  NSString *label1 = [NSString stringWithFormat:NSLocalizedString(@"There are no bookmarks for %@", nil), self.bookTitle];
  NSString *label2 = NSLocalizedString(@"There are no bookmarks for this book.", nil);
  if (self.bookTitle) {
    self.noBookmarksLabel.text = label1;
  } else {
    self.noBookmarksLabel.text = label2;
  }

  [self.view insertSubview:self.noBookmarksLabel belowSubview:self.tableView];
  
  [self.noBookmarksLabel autoCenterInSuperview];
  [self.noBookmarksLabel autoSetDimension:ALDimensionWidth toSize:250];
}

- (void)showAlertForFailedSync
{
  UIAlertController *alert = [NYPLAlertUtils
                              alertWithTitle:@"Error Syncing Bookmarks"
                              message:@"There was an error syncing bookmarks to the server. Ensure your device is connected to the internet or try again later."];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
