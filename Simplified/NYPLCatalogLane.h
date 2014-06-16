@import Foundation;

@interface NYPLCatalogLane : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NSString *title;

// designated initializer
- (id)initWithBooks:(NSArray *)books
              title:(NSString *)title;

@end
