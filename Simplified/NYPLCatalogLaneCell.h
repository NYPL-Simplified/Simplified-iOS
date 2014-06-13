@import Foundation;

@class NYPLCatalogLaneCell;

@protocol NYPLCatalogLaneCellDelegate <NSObject>

- (void)catalogLaneCell:(NYPLCatalogLaneCell *)cell
 didSelectBookIndex:(NSUInteger)bookIndex;

@end

@interface NYPLCatalogLaneCell : UITableViewCell

@property (nonatomic, readonly) NSUInteger categoryIndex;
@property (nonatomic, weak) id<NYPLCatalogLaneCellDelegate> delegate;

// designated initializer
- (id)initWithCategoryIndex:(NSUInteger)index
            reuseIdentifier:(NSString *)reuseIdentifier;

- (void)useImageDataArray:(NSArray *)imageDataArray;

@end
