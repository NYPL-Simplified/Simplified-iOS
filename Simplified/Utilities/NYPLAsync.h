// Using this function is equivalent to using |dispatch_async| with the default global priority
// queue.
void NYPLAsyncDispatch(dispatch_block_t block);