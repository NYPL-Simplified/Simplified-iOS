#import "NYPLConfiguration.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCCell.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReadium.h"

#import "NYPLReaderTOCViewController.h"

@interface NYPLReaderTOCViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) RDNavigationElement *navigationElement;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)didSelectSegment:(id)sender;

@end

static NSString *const reuseIdentifierTOC = @"contentCell";
static NSString *const reuseIdentifierBookmark = @"bookmarkCell";


@implementation NYPLReaderTOCViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  
  self.title = NSLocalizedString(@"ReaderTOCViewControllerTitle", nil);
  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  switch([NYPLReaderSettings sharedSettings].colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.tableView.backgroundColor = [NYPLConfiguration backgroundDarkColor];
      break;
  }
  
  [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  NSUInteger numRows = 0;
  
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:
      numRows = self.tableOfContents.count;
      break;
    case 1:
      numRows = self.bookmarks.count;
      break;
    default:
      break;
  }
  
  return numRows;
}

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:{
      NYPLReaderTOCCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifierTOC];
      NYPLReaderTOCElement *const toc = self.tableOfContents[indexPath.row];
  
      cell.leadingEdgeConstraint.constant = 0;
      if (toc.nestingLevel > 0) {
            cell.leadingEdgeConstraint.constant = toc.nestingLevel * 20 + 10;
      }
      cell.titleLabel.text = toc.title;

      return cell;
    }
    case 1:{
      return nil;
    }
    default:
      return nil;
  }
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *const)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:{
      NYPLReaderTOCElement *const TOCElement = self.tableOfContents[indexPath.row];
      [self.delegate TOCViewController:self
               didSelectOpaqueLocation:TOCElement.opaqueLocation];
      break;
    }
    case 1:{
      // bookmark selected
    }
    default:
      break;
  }
}

-(CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView estimatedHeightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:
      return 56;
    case 1:
      return 100;
    default:
      return 44;
  }
}

-(CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  switch (self.segmentedControl.selectedSegmentIndex) {
    case 0:
    case 1:
      return UITableViewAutomaticDimension;
    default:
      return 44;
  }
}

- (IBAction)didSelectSegment:(__attribute__((unused)) UISegmentedControl*)sender
{
  [self.tableView reloadData];
}
@end
