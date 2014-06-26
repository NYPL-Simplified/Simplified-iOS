@class NYPLCatalogLaneCell;

@protocol NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *)cell
 didSelectBookIndex:(NSUInteger)bookIndex;

@end

@interface NYPLCatalogLaneCell : UITableViewCell

@property (nonatomic, weak) id<NYPLCatalogLaneCellDelegate> delegate;
@property (nonatomic, readonly) NSUInteger laneIndex;

// designated initializer
- (instancetype)initWithLaneIndex:(NSUInteger)laneIndex
                            books:(NSArray *)books
              imageDataDictionary:(NSDictionary *)imageDataDictionary;

@end
