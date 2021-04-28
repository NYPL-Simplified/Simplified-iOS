#import "NYPLBook.h"

#import "NYPLTenPrintCoverView+NYPLImageAdditions.h"

// FIXME: This is a hack to work around an issue in TenPrintCoverView in which the height of the
// author line does not scale with the size of the cover itself. We set |authorHeight| to a value in
// |initialize| so that the author text is restricted to a single line given the size of covers used
// in the app. This needs to be fixed properly in TenPrintCoverView eventually, especially since
// this hack shouldn't even work to begin with. (It only works because |authorHeight| is not
// correctly declared as a static variable in TenPrintCoverView.)
extern int authorHeight;

@implementation NYPLTenPrintCoverView (NYPLTenPrintCoverView_NYPLImageAdditions)

+ (void)initialize {
  authorHeight = 15;
}

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
  [coverView.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *const image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

@end
