#import "NYPLMyBooksState.h"

@class NYPLBook;
@class NYPLBookLocation;

@interface NYPLMyBooksRecord : NSObject

@property (nonatomic, readonly) NYPLBook *book;
@property (nonatomic, readonly) NYPLBookLocation *location; // nilable
@property (nonatomic, readonly) NYPLMyBooksState state;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBook:(NYPLBook *)book
                    location:(NYPLBookLocation *)location
                       state:(NYPLMyBooksState)state;

// designated initialzier
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (instancetype)recordWithBook:(NYPLBook *)book;

- (instancetype)recordWithLocation:(NYPLBookLocation *)location;

- (instancetype)recordWithState:(NYPLMyBooksState)state;

@end
