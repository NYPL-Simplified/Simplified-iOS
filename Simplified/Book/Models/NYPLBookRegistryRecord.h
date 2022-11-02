// This class is intended for internal use by NYPLBookRegistry.

@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReadiumBookmark;
@class NYPLAudiobookBookmark;
typedef NS_ENUM(NSInteger, NYPLBookState);

@interface NYPLBookRegistryRecord : NSObject

@property (nonatomic, readonly) NYPLBook *book;
@property (nonatomic, readonly) NYPLBookLocation *location; // nilable
@property (nonatomic, readonly) NYPLBookState state;
@property (nonatomic, readonly) NSString *fulfillmentId; // nilable
@property (nonatomic, readonly) NSArray<NYPLReadiumBookmark *> *readiumBookmarks; // nilable
@property (nonatomic, readonly) NSArray<NYPLAudiobookBookmark *> *audiobookBookmarks; // nilable
@property (nonatomic, readonly) NSArray<NYPLBookLocation *> *genericBookmarks; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBook:(NYPLBook *)book
                    location:(NYPLBookLocation *)location
                       state:(NYPLBookState)state
               fulfillmentId:(NSString *)fulfillmentId
            readiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)readiumBookmarks
          audiobookBookmarks:(NSArray<NYPLAudiobookBookmark *> *)audiobookBookmarks
            genericBookmarks:(NSArray<NYPLBookLocation *> *)genericBookmarks;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (instancetype)recordWithBook:(NYPLBook *)book;

- (instancetype)recordWithLocation:(NYPLBookLocation *)location;

- (instancetype)recordWithState:(NYPLBookState)state;

- (instancetype)recordWithFulfillmentId:(NSString *)fulfillmentId;

- (instancetype)recordWithReadiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)bookmarks;

- (instancetype)recordWithAudiobookBookmarks:(NSArray<NYPLAudiobookBookmark *> *)bookmarks;

- (instancetype)recordWithGenericBookmarks:(NSArray<NYPLBookLocation *> *)bookmarks;

@end
