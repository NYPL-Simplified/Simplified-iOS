@interface NYPLCatalogFacet : NSObject

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) NSURL *href;
@property (nonatomic, readonly) NSString *title;

- (instancetype)initWithActive:(BOOL)active
                          href:(NSURL *)href
                         title:(NSString *)title;

@end
