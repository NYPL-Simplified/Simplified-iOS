@interface NYPLSession : NSObject

+ (nonnull id)new NS_UNAVAILABLE;
- (nonnull id)init NS_UNAVAILABLE;

+ (nonnull NYPLSession *)sharedSession;

- (void)uploadWithRequest:(nonnull NSURLRequest *)request
        completionHandler:(void (^ _Nullable)(NSData * _Nullable data,
                                              NSURLResponse * _Nullable response,
                                              NSError * _Nullable error))handler;

/**
 Executes GET request for given URL, unless the URL path ends in "borrow", in
 which cast a PUT is executed instead.
 @param URL The endpoint to reach
 @param shouldResetCache Pass YES to wipe the whole cache for this session.
 @param handler This handler is always called once a response is received.
 If @p error is not nil, @p data is always nil.
 If @p error is nil, @p data may also be nil.
 @return The request that was issued.
 */
- (void)  withURL:(nonnull NSURL *)URL
 shouldResetCache:(BOOL)shouldResetCache
completionHandler:(void (^ _Nonnull)(NSData * _Nullable data,
                                     NSURLResponse * _Nullable response,
                                     NSError * _Nullable error))handler;

@end
