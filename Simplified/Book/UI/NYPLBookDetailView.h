#import "NYPLBookButtonsView.h"

@class NYPLBook;
@class NYPLBookDetailView;
@class NYPLBookDetailTableViewDelegate;
@class NYPLCatalogLane;
@class NYPLBookDetailTableView;
typedef NS_ENUM(NSInteger, NYPLBookState);
@protocol NYPLCatalogLaneCellDelegate;

@protocol NYPLBookDetailViewDelegate <NYPLBookButtonsDelegate>

- (void)didSelectCancelDownloadFailedForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectCancelDownloadingForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectCloseButton:(NYPLBookDetailView *)detailView;
- (void)didSelectMoreBooksForLane:(NYPLCatalogLane *)lane;
- (void)didSelectReportProblemForBook:(NYPLBook *)book sender:(id)sender;
- (void)didSelectViewIssuesForBook:(NYPLBook *)book sender:(id)sender;

@end

static CGFloat const SummaryTextAbbreviatedHeight = 150.0;

@interface NYPLBookDetailView : UIScrollView

@property (nonatomic) NYPLBook *book;
@property (nonatomic) double downloadProgress;
@property (nonatomic) BOOL downloadStarted;
@property (nonatomic) NYPLBookState state;
@property (nonatomic) NYPLBookDetailTableViewDelegate *tableViewDelegate;
@property (nonatomic, readonly) UIButton *readMoreLabel;
@property (nonatomic, readonly) UITextView *summaryTextView;
@property (nonatomic, readonly) NYPLBookDetailTableView *footerTableView;


+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *const)book
                    delegate:(id<NYPLBookDetailViewDelegate, NYPLCatalogLaneCellDelegate>)delegate;
- (void)updateFonts;

@end

