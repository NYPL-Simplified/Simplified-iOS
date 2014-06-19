@import Foundation;

@class NYPLCatalogLaneCell;

@protocol NYPLCatalogLaneCellDelegate <NSObject>

- (void)catalogLaneCell:(NYPLCatalogLaneCell *)cell
 didSelectBookIndex:(NSUInteger)bookIndex;

@end

@interface NYPLCatalogLaneCell : UITableViewCell

@property (nonatomic, weak) id<NYPLCatalogLaneCellDelegate> delegate;
@property (nonatomic, readonly) NSUInteger laneIndex;

// designated initializer
- (id)initWithLaneIndex:(NSUInteger)laneIndex
                  books:(NSArray *)books
    imageDataDictionary:(NSDictionary *)imageDataDictionary;

@end
