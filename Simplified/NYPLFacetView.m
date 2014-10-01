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
  [self.scrollView removeFromSuperview];
  
  self.linearView = [[NYPLLinearView alloc] init];
  
  self.scrollView = [[UIScrollView alloc] init];
  [self.scrollView addSubview:self.linearView];
  [self addSubview:self.scrollView];
  
  self.groupIndexesToFacetNames = [NSMutableArray array];
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
    
    UILabel *const groupLabel = [[UILabel alloc] init];
    groupLabel.font = [UIFont systemFontOfSize:12];
    groupLabel.text = [[self.dataSource facetView:self nameForFacetGroupAtIndex:groupIndex]
                       stringByAppendingString:@":"];
    [self.linearView addSubview:groupLabel];
    
    NYPLRoundedButton *const button = [NYPLRoundedButton button];
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.linearView addSubview:button];
    
    if([self.dataSource facetView:self isActiveFacetForFacetGroupAtIndex:groupIndex]) {
      NSUInteger const facetIndex = [self.dataSource
                                     facetView:self
                                     activeFacetIndexForFacetGroupAtIndex:groupIndex];
      NSUInteger const indexes[2] = {groupIndex, facetIndex};
      NSIndexPath *const indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
      NSString *const facetName = [self.dataSource
                                   facetView:self
                                   nameForFacetAtIndexPath:indexPath];
      [button setTitle:facetName forState:UIControlStateNormal];
    } else {
      [button setTitle:NSLocalizedString(@"FacetViewNotActive", nil)
              forState:UIControlStateNormal];
    }
    
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
  }
}

@end
