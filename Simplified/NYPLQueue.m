#import "NYPLQueue.h"

@interface NYPLQueueElement : NSObject

@property (nonatomic) id head;
@property (nonatomic) NYPLQueueElement *tail;

@end

@implementation NYPLQueueElement

@end

@interface NYPLQueue ()

@property (nonatomic) NSUInteger internalCount;
@property (nonatomic) NYPLQueueElement *first;
@property (nonatomic) NYPLQueueElement *last;

@end

@implementation NYPLQueue

+ (instancetype)queue
{
  return [[self alloc] init];
}

- (void)enqueue:(id const)object
{
  if(!object) {
    @throw NSInvalidArgumentException;
  }
  
  NYPLQueueElement *const element = [[NYPLQueueElement alloc] init];
  element.head = object;
  
  @synchronized(self) {
    self.last.tail = element;
    self.last = element;
    if(!self.first) {
      self.first = self.last;
    }
    ++self.internalCount;
  }
}

- (id)dequeue
{
  @synchronized(self) {
    NYPLQueueElement *const first = self.first;
    if(first) {
      self.first = first.tail;
    }
    --self.internalCount;
    
    return first.head;
  }
}

- (id)peek
{
  @synchronized(self) {
    return self.first;
  }
}

- (NSUInteger)count
{
  @synchronized(self) {
    return self.internalCount;
  }
}

@end
