#import "NYPLAdeptConnectorOperation.h"

@interface NYPLAdeptConnectorOperation ()

@property (nonatomic) void (^block)();

@end

@implementation NYPLAdeptConnectorOperation

+ (instancetype)operationWithBlock:(void (^)())block
{
  return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(void (^)())block
{
  self = [super init];
  if(!self) return nil;
  
  self.block = block;
  
  return self;
}

@end
