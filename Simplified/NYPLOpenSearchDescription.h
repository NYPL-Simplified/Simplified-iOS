@class NYPLXML;

@interface NYPLOpenSearchDescription : NSObject

@property (nonatomic, readonly) NSString *OPDSURLTemplate; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (void)withURL:(NSURL *)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *description))handler;

- (instancetype)initWithXML:(NYPLXML *)OSDXML;

@end
