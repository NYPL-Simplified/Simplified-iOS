// This class is used to represent OpenSearch description documents. It is restricted to documents
// that contain URLs to OPDS feeds: Calling |initWithXML:| with anything else will return nil.

@class NYPLXML;

@interface NYPLOpenSearchDescription : NSObject

@property (nonatomic, readonly) NSString *humanReadableDescription;
@property (nonatomic, readonly) NSString *OPDSURLTemplate;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (void)withURL:(NSURL *)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *description))handler;

- (instancetype)initWithXML:(NYPLXML *)OSDXML;

@end
