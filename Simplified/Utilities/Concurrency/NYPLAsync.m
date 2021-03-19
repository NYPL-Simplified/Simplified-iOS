#import "NYPLAsync.h"

void NYPLAsyncDispatch(dispatch_block_t const block)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}
