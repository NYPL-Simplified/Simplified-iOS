#import "NYPLCatalogLaneCell.h"

@implementation NYPLCatalogLaneCell

- (id)initWithTitle:(NSString *)title
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 200, 20)];
  titleLabel.text = title;
  [self addSubview:titleLabel];
  
  return self;
}

@end
