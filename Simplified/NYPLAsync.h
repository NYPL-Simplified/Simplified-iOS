// |data| will be |nil| if an error occurred.
// The handler is guaranteed to be called on the main thread.
void NYPLAsyncFetch(NSURL *url, void (^ handler)(NSData *data));

// The handler will be called with a dictionary containing all input URLs as keys.
// Each key will be associated with an NSData value if successful, else an NSNull value.
// The handler is guaranteed to be called on the main thread.
void NYPLAsyncFetchSet(NSSet *set, void (^ handler)(NSDictionary *dataDictionary));