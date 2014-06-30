#import "NYPLCatalogBook.h"

@interface NYPLBookDetailView : UIScrollView

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLCatalogBook *)book
                  coverImage:(UIImage *)coverImage;

@end
