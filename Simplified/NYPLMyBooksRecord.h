#import "NYPLBook.h"
#import "NYPLMyBooksState.h"

typedef NS_ENUM(NSInteger, NYPLMyBooksRecordState) {
  NYPLMyBooksRecordStateDownloading
};

@interface NYPLMyBooksRecord : NSObject

@property (nonatomic, readonly) NYPLBook *book;
@property (nonatomic, readonly) NYPLMyBooksState state;

+ (instancetype)recordWithDictionary:(NSDictionary *)dictionary;

// designated initializer
- (instancetype)initWithBook:(NYPLBook *)book state:(NYPLMyBooksState)state;

- (instancetype)recordWithBook:(NYPLBook *)book;

- (instancetype)recordWithState:(NYPLMyBooksState)state;

- (NSDictionary *)dictionaryRepresentation;

@end
