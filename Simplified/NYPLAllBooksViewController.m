#import "NYPLAllBooksViewController.h"

@implementation NYPLAllBooksViewController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = @"All Books";
  
  return self;
}

@end
