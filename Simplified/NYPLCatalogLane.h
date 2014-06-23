@import Foundation;

#import "NYPLCatalogSubsectionLink.h"

@interface NYPLCatalogLane : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NYPLCatalogSubsectionLink *subsectionLink;
@property (nonatomic, readonly) NSString *title;

// designated initializer
- (id)initWithBooks:(NSArray *)books
     subsectionLink:(NYPLCatalogSubsectionLink *)subsectionLink
              title:(NSString *)title;

- (NSSet *)imageURLs;

@end
