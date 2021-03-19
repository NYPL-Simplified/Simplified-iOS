@interface NYPLOPDSGroup : NSObject

@property (nonatomic, readonly) NSArray *entries;
@property (nonatomic, readonly) NSURL *href;
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// Throws |NSInvalidArgumentException| if any arguments are nil or if entries are not all of type
// NYPLOPDSEntry.
- (instancetype)initWithEntries:(NSArray *)entries
                           href:(NSURL *)href
                          title:(NSString *)title;

@end
