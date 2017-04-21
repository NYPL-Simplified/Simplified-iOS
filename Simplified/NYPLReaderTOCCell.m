#import "NYPLReaderTOCCell.h"

@implementation NYPLReaderTOCCell

#pragma mark UIView

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  CGRect frame = self.contentView.bounds;
  if (self.nestingLevel > 0) {
    frame.origin.x = self.nestingLevel * 20 + 10;
    frame.size.width -= self.nestingLevel * 20 + 20;
    self.titleLabel.frame = frame;
  }
}


@end
