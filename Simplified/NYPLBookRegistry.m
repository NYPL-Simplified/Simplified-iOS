#import "NYPLBookRegistry.h"

@interface NYPLBookRegistry ()

@property (nonatomic) NSMutableDictionary *identifiersToBooks;

@end

@implementation NYPLBookRegistry

+ (NYPLBookRegistry *)sharedInstance
{
  static dispatch_once_t predicate;
  static NYPLBookRegistry *sharedContentRegistry = nil;
  
  dispatch_once(&predicate, ^{
    sharedContentRegistry = [[NYPLBookRegistry alloc] init];
    if(!sharedContentRegistry) {
      NYPLLOG(@"Failed to create shared content registry.");
    }
  });
  
  return sharedContentRegistry;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.identifiersToBooks = [NSMutableDictionary dictionary];
  
  return self;
}

#pragma mark -

- (void)addBook:(NYPLBook *const)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    self.identifiersToBooks[book.identifier] = book;
  }
}

- (void)updateBook:(NYPLBook *const)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    if(self.identifiersToBooks[book.identifier]) {
      self.identifiersToBooks[book.identifier] = book;
    }
  }
}

- (void)removeBookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    [self.identifiersToBooks removeObjectForKey:identifier];
  }
}

@end
