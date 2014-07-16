#import "NYPLMyBooksDownloadCenter.h"

#import "NYPLBookDetailViewDelegate.h"

@implementation NYPLBookDetailViewDelegate

+ (instancetype)sharedDelegate
{
  static dispatch_once_t predicate;
  static NYPLBookDetailViewDelegate *sharedDelegate = nil;
  
  dispatch_once(&predicate, ^{
    sharedDelegate = [[self alloc] init];
    if(!sharedDelegate) {
      NYPLLOG(@"Failed to create shared delegate.");
    }
  });
  
  return sharedDelegate;
}

- (void)didSelectDownloadForDetailView:(NYPLBookDetailView *const)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:detailView.book];
}

@end
