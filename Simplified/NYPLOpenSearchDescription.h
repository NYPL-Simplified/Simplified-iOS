@class SMXMLDocument;

@interface NYPLOpenSearchDescription : NSObject

@property (nonatomic, readonly) NSString *OPDSURLTemplate; // nilable

+ (void)withURL:(NSURL *)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *description))handler;

- (instancetype)initWithDocument:(SMXMLDocument *)document;

@end
