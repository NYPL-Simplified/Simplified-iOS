#import "NYPLBookState.h"

@class NYPLBook;

@class NYPLBookDetailView;

@protocol NYPLBookDetailViewDelegate

- (void)didSelectCancelDownloadFailedForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectCancelDownloadingForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectReturnForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectDownloadForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectReadForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectCloseButton:(NYPLBookDetailView *)detailView;
- (void)didSelectReportProblemForBook:(NYPLBook *)book sender:(id)sender;

@end

@interface NYPLBookDetailView : UIScrollView

@property (nonatomic) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDetailViewDelegate> detailViewDelegate;
@property (nonatomic) double downloadProgress;
@property (nonatomic) BOOL downloadStarted;
@property (nonatomic) NYPLBookState state;
@property (nonatomic) UIButton *reportProblemLabel;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;
- (void)updateFonts;

@end

