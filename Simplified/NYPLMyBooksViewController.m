#import "NYPLMyBooksViewController.h"

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  return self;
}

@end
