@class NYPLCatalogCategory;

@protocol NYPLCatalogCategoryDelegate

- (void)catalogCategory:(NYPLCatalogCategory *)catalogCategory
         didUpdateBooks:(NSArray *)books;

@end

@interface NYPLCatalogCategory : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, weak) id<NYPLCatalogCategoryDelegate> delegate; // nilable
@property (nonatomic, readonly) NSURL *nextURL; // nilable
@property (nonatomic, readonly) NSString *searchTemplate; // nilable
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)URL handler:(void (^)(NYPLCatalogCategory *category))handler;

// designated initializer
- (instancetype)initWithBooks:(NSArray *)books
                      nextURL:(NSURL *)nextURL
               searchTemplate:(NSString *)searchTemplate
                        title:(NSString *)title;

// This method is used to inform a catalog category that the data of a book at the given index is
// being used elsewhere. This knowledge allows preemptive retrieval of the next URL (if present) so
// that later books will be available upon request. It is important to have a delegate receive
// updates as it's the only way of knowing when data about new books has actually become available.
// It is an error to attempt to prepare for a book index equal to greater than |books.count|,
// something avoidable because book counts never decrease.
- (void)prepareForBookIndex:(NSUInteger)bookIndex;

@end