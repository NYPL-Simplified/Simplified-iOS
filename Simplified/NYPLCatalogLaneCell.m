#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) NSUInteger categoryIndex;

@end

@implementation NYPLCatalogLaneCell

- (id)initWithCategoryIndex:(NSUInteger const)index
            reuseIdentifier:(NSString *const)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if(!self) return nil;
  
  self.categoryIndex = index;
  
  return self;
}

- (void)useImageDataArray:(NSArray *)imageDataArray
{
  for(UIView *const button in self.buttons) {
    [button removeFromSuperview];
  }
  
  [self.buttons removeAllObjects];
  
  for(NSData *const data in imageDataArray) {
    // TODO
    NSLog(@"%@", data);
  }
}

@end
