@import Foundation;

@interface NYPLCatalogCategory : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NSString *title;

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)url handler:(void (^)(NYPLCatalogCategory *category))handler;

// designated initializer
- (id)initWithBooks:(NSArray *)books
              title:(NSString *)title;

@end
