// This class serves as a wrapper for NYPLFacetView in order to provide a more toolbar-like
// appearance. It is assumed that it will be anchored to the top of the screen below a status bar
// or navigation bar.

@class NYPLFacetView;

@interface NYPLFacetBarView : UIView

@property (nonatomic, readonly) NYPLFacetView *facetView;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithOrigin:(CGPoint)origin width:(CGFloat)width;

@end
