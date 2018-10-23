#import "NYPLFacetView.h"
#import "SimplyE-Swift.h"
#import <PureLayout/PureLayout.h>

#import "NYPLFacetBarView.h"

@interface NYPLFacetBarView ()

@property (nonatomic) NYPLEntryPointView *entryPointView;
@property (nonatomic) NYPLFacetView *facetView;

@end

@implementation NYPLFacetBarView

- (instancetype)initWithOrigin:(CGPoint const)origin width:(CGFloat const)width
{
  CGFloat const borderHeight = 1.0 / [UIScreen mainScreen].scale;
  CGFloat const toolbarHeight = 40;
  
  self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, borderHeight + toolbarHeight)];
  if(!self) return nil;

  UIVisualEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
  UIVisualEffectView *bgBlur = [[UIVisualEffectView alloc] initWithEffect:blur];

  [self addSubview:bgBlur];
  [bgBlur autoPinEdgesToSuperviewEdges];

  self.entryPointView = [[NYPLEntryPointView alloc] init];
  self.facetView = [[NYPLFacetView alloc] init];
  self.entryPointView.hidden = YES;
  self.facetView.hidden = YES;

  UIView *bottomBorderView = [[UIView alloc] init];
  bottomBorderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.9];
  UIView *topBorderView = [[UIView alloc] init];
  topBorderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.9];

  [self addSubview:self.facetView];
  [self addSubview:self.entryPointView];
  [self.entryPointView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
  [self.facetView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
  [self.entryPointView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.facetView];

  [self.facetView addSubview:bottomBorderView];
  [bottomBorderView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
  [bottomBorderView autoSetDimension:ALDimensionHeight toSize:borderHeight];
  [self.facetView addSubview:topBorderView];
  [topBorderView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
  [topBorderView autoSetDimension:ALDimensionHeight toSize:borderHeight];

  return self;
}

@end
