#import "NYPLMyBooksState.h"

@class NYPLBook;

@class NYPLBookDetailView;

@protocol NYPLBookDetailViewDelegate

- (void)didSelectCancelDownloadFailedForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectCancelDownloadingForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectDeleteForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectDownloadForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectReadForBookDetailView:(NYPLBookDetailView *)detailView;
- (void)didSelectTryAgainForBookDetailView:(NYPLBookDetailView *)detailView;

@end

@interface NYPLBookDetailView : UIScrollView

@property (nonatomic, readonly) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDetailViewDelegate> detailViewDelegate;
@property (nonatomic) double downloadProgress;
@property (nonatomic) NYPLMyBooksState state;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

@end

