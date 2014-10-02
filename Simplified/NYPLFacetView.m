#import "NYPLLinearView.h"
#import "NYPLRoundedButton.h"

#import "NYPLFacetView.h"

@interface NYPLFacetView ()

@property (nonatomic) NSMutableArray *groupIndexesToFacetNames;
@property (nonatomic) NYPLLinearView *linearView;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation NYPLFacetView

- (void)setDataSource:(id<NYPLFacetViewDataSource> const)dataSource
{
  _dataSource = dataSource;
  
  if(self.dataSource && self.delegate) {
    [self reloadData];
  }
}

- (void)setDelegate:(id<NYPLFacetViewDelegate> const)delegate
{
  _delegate = delegate;
  
  if(self.dataSource && self.delegate) {
    [self reloadData];
  }
}

- (void)reset
{
  self.groupIndexesToFacetNames = [NSMutableArray array];
 
  [self.scrollView removeFromSuperview];
  
  self.scrollView = [[UIScrollView alloc] init];
  [self addSubview:self.scrollView];
  
  self.linearView = [[NYPLLinearView alloc] init];
  self.linearView.contentVerticalAlignment = NYPLLinearViewContentVerticalAlignmentMiddle;
  self.linearView.padding = 8.0;
  [self.scrollView addSubview:self.linearView];
}

- (void)reloadData
{
  if(!(self.dataSource && self.delegate)) {
    NYPLLOG(@"Ignoring attempt to reload data without a data source and delegate.");
    return;
  }
  
  [self reset];
  
  NSUInteger const groupCount = [self.dataSource numberOfFacetGroupsInFacetView:self];
  
  for(NSUInteger groupIndex = 0; groupIndex < groupCount; ++groupIndex) {
    NSUInteger const facetCount = [self.dataSource
                                   facetView:self
                                   numberOfFacetsInFacetGroupAtIndex:groupIndex];
    
    NSMutableArray *const facetNames = [NSMutableArray arrayWithCapacity:facetCount];
    [self.groupIndexesToFacetNames addObject:facetNames];
    
    for(NSUInteger facetIndex = 0; facetIndex < facetCount; ++facetIndex) {
      NSUInteger const indexes[2] = {groupIndex, facetIndex};
      NSIndexPath *const indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
      NSString *const facetName = [self.dataSource
                                   facetView:self
                                   nameForFacetAtIndexPath:indexPath];
      [facetNames addObject:facetName];
    }

    UILabel *const groupLabel = [[UILabel alloc] init];
    groupLabel.font = [UIFont systemFontOfSize:17];
    groupLabel.text = [[self.dataSource facetView:self nameForFacetGroupAtIndex:groupIndex]
                       stringByAppendingString:@":"];
    [self.linearView addSubview:groupLabel];

    NYPLRoundedButton *const button = [NYPLRoundedButton button];
    button.titleLabel.font = [UIFont systemFontOfSize:17];
    if([self.dataSource facetView:self isActiveFacetForFacetGroupAtIndex:groupIndex]) {
      NSUInteger const facetIndex = [self.dataSource
                                     facetView:self
                                     activeFacetIndexForFacetGroupAtIndex:groupIndex];
      [button setTitle:self.groupIndexesToFacetNames[groupIndex][facetIndex]
              forState:UIControlStateNormal];
    } else {
      [button setTitle:NSLocalizedString(@"FacetViewNotActive", nil)
              forState:UIControlStateNormal];
    }
    [self.linearView addSubview:button];
  }
  
  if(self.superview) {
    [self setNeedsLayout];
  }
}

#pragma mark UIView

- (void)layoutSubviews
{
  for(UIView *const view in self.linearView.subviews) {
    [view sizeToFit];
  }
  
  [self.linearView sizeToFit];
  
  self.scrollView.frame = self.bounds;
  self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.linearView.frame),
                                           CGRectGetHeight(self.frame));
}

@end
