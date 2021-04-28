// Due to differences in how different renderers (e.g. Readium, RMSDK, et cetera) want to handle
// location information, it is necessary to store location information in an unstructured manner.
// When creating an instance of this class, |locationString| is the renderer-specific data and
// |renderer| is a string that uniquely identifies the renderer that generated it. When loading a
// location, renderers can inspect |renderer| to ensure the location string they're about to use is
// compatible with their underlying systems.

@interface NYPLBookLocation : NSObject

@property (nonatomic, readonly) NSString *locationString;
@property (nonatomic, readonly) NSString *renderer;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithLocationString:(NSString *)locationString
                              renderer:(NSString *)renderer;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
