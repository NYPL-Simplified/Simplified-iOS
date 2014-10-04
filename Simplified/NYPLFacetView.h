@class NYPLFacetView;

@protocol NYPLFacetViewDataSource

- (NSUInteger)numberOfFacetGroupsInFacetView:(NYPLFacetView *)facetView;

- (NSUInteger)facetView:(NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(NSUInteger)index;

- (NSString *)facetView:(NYPLFacetView *)facetView nameForFacetGroupAtIndex:(NSUInteger)index;

- (NSString *)facetView:(NYPLFacetView *)facetView nameForFacetAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)facetView:(NYPLFacetView *)facetView isActiveFacetForFacetGroupAtIndex:(NSUInteger)index;

- (NSUInteger)facetView:(NYPLFacetView *)facetView
activeFacetIndexForFacetGroupAtIndex:(NSUInteger)index;

@end

@protocol NYPLFacetViewDelegate

- (void)facetView:(NYPLFacetView *)facetView didSelectFacetAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface NYPLFacetView : UIView

@property (nonatomic, weak) id<NYPLFacetViewDataSource> dataSource;
@property (nonatomic, weak) id<NYPLFacetViewDelegate> delegate;

- (void)reloadData;

@end
