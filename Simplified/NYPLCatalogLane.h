@import Foundation;

@interface NYPLCatalogLane : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NSURL *subsectionURL;
@property (nonatomic, readonly) NSString *title;

// designated initializer
- (id)initWithBooks:(NSArray *)books
      subsectionURL:(NSURL *)subsectionURL
              title:(NSString *)title;

- (NSSet *)imageURLs;

@end
