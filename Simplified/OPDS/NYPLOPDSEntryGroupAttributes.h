@interface NYPLOPDSEntryGroupAttributes : NSObject

@property (nonatomic, readonly) NSURL *href; // nilable
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// Throws |NSInvalidArgumentException| if |title| is nil.
- (instancetype)initWithHref:(NSURL *)href title:(NSString *)title;

@end
