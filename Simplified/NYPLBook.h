#import "NYPLBookAcquisition.h"
#import "NYPLOPDSEntry.h"

typedef NS_ENUM(NSInteger, NYPLBookState) {
  NYPLBookStateDefault,
  NYPLBookStateDownloading
};

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NYPLBookAcquisition *acquisition;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NYPLBookState state;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *const)entry state:(NYPLBookState)state;

// designated initializer
- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                              state:(NYPLBookState)state
                              title:(NSString *)title
                            updated:(NSDate *)updated;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Returns a copy of the book with a new state.
- (instancetype)bookWithState:(NYPLBookState)state;

- (NSDictionary *)dictionaryRepresentation;

@end
