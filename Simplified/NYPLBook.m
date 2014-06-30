#import "NYPLBook.h"

@interface NYPLBook ()

@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *title;

@end

@implementation NYPLBook

- (instancetype)initWithAuthorStrings:(NSArray *const)authorStrings
                           identifier:(NSString *const)identifier
                                title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(authorStrings && identifier && title)) {
    @throw NSInvalidArgumentException;
  }
  
  self.authorStrings = authorStrings;
  self.identifier = identifier;
  self.title = title;
  
  return self;
}

@end
