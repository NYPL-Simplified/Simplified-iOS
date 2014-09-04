@class NYPLXML;

@interface NYPLOpenSearchDescription : NSObject

@property (nonatomic, readonly) NSString *OPDSURLTemplate; // nilable

+ (void)withURL:(NSURL *)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *description))handler;

- (instancetype)initWithXML:(NYPLXML *)OSDXML;

@end
