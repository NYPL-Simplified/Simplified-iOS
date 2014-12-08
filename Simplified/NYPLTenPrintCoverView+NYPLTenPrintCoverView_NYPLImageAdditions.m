#import "NYPLBook.h"

#import "NYPLTenPrintCoverView+NYPLTenPrintCoverView_NYPLImageAdditions.h"

@implementation NYPLTenPrintCoverView (NYPLTenPrintCoverView_NYPLImageAdditions)

+ (UIImage *)imageForBook:(NYPLBook *const)book
{
  CGFloat const width = 80;
  CGFloat const height = 120;
  
  // The scale argument below refers to the size of the font and nothing to do with the scale used
  // for rendering by the main screen.
  NYPLTenPrintCoverView *const coverView =
    [[NYPLTenPrintCoverView alloc]
     initWithFrame:CGRectMake(0, 0, width, height)
     withTitle:book.title
     withAuthor:book.authors
     withScale:0.4];
  
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
  [coverView drawViewHierarchyInRect:coverView.bounds afterScreenUpdates:YES];
  UIImage *const image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

@end
