#import "NYPLBookAcquisition.h"
#import "NYPLOPDSEntry.h"

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NYPLBookAcquisition *acquisition;
@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *const)entry;

// designated initializer
- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                              title:(NSString *)title
                            updated:(NSDate *)updated;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
