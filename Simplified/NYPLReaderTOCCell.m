
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCCell.h"

@interface NYPLReaderTOCCell ()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation NYPLReaderTOCCell

#pragma mark UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if(!self) return nil;
  
  self.titleLabel = [[UILabel alloc] init];
  [self.contentView addSubview:self.titleLabel];
  
  self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  self.titleLabel.textColor = [NYPLReaderSettings sharedSettings].foregroundColor;

  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGRect frame = self.contentView.bounds;
  frame.origin.x = self.nestingLevel * 20 + 10;
  frame.size.width -= self.nestingLevel * 20 + 20;
  self.titleLabel.frame = frame;
}

#pragma mark -

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
  _nestingLevel = nestingLevel;
  
  [self setNeedsLayout];
}

- (NSString *)title
{
  return self.titleLabel.text;
}

- (void)setTitle:(NSString *const)title
{
  self.titleLabel.text = title;
}

@end
