#import "NYPLMyBooksViewController.h"

@implementation NYPLMyBooksViewController

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  return self;
}

@end
