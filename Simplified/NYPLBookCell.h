#import "NYPLBook.h"

CGSize NYPLBookCellSizeForIdiomAndOrientation(UIUserInterfaceIdiom idiom,
                                              UIInterfaceOrientation orientation);

@interface NYPLBookCell : UICollectionViewCell

- (void)setBook:(NYPLBook *)book;

@end
