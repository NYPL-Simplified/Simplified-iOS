@class NYPLFacetView;

@protocol NYPLFacetViewDataSource

- (NSUInteger)numberOfFacetGroupsInFacetView:(NYPLFacetView *)facetView;

- (NSUInteger)facetView:(NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(NSUInteger)index;

- (NSString *)facetView:(NYPLFacetView *)facetView nameForFacetGroupAtIndex:(NSUInteger)index;

- (NSString *)facetView:(NYPLFacetView *)facetView nameForFacetAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol NYPLFacetViewDelegate

- (void)facetView:(NYPLFacetView *)facetView didSelectFacetAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface NYPLFacetView : UIView

@property (nonatomic, weak) id<NYPLFacetViewDataSource> dataSource;
@property (nonatomic, weak) id<NYPLFacetViewDelegate> delegate;

- (void)reloadData;

@end
