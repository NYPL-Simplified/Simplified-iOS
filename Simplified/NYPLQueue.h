// This is a simple implementation of a thread-safe FIFO queue.

@interface NYPLQueue : NSObject

// O(1).
@property (atomic, readonly) NSUInteger count;

+ (instancetype)queue;

// O(1). |object| must not be nil.
- (void)enqueue:(id)object;

// O(1). Returns nil if empty.
- (id)dequeue;

// O(1). Returns the next object that can be dequeued, but does not actually remove it.
- (id)peek;

@end
