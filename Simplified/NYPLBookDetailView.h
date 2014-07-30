#import "NYPLMyBooksState.h"

@class NYPLBook;

@class NYPLBookDetailView;

@protocol NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(NYPLBookDetailView *)detailView;

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

