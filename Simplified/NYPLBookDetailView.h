#import "NYPLBook.h"

@class NYPLBookDetailView;

@protocol NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(NYPLBookDetailView *)detailView;

@end

@interface NYPLBookDetailView : UIScrollView

@property (nonatomic, readonly) NYPLBook *book;
@property (nonatomic, weak) id<NYPLBookDetailViewDelegate> detailViewDelegate;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

@end

