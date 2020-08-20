// This class is used to represent OpenSearch description documents. It is restricted to documents
// that contain URLs to OPDS feeds: Calling |initWithXML:| with anything else will return nil.

@import Foundation;

@class NYPLXML;

@interface NYPLOpenSearchDescription : NSObject

@property (nonatomic, readonly) NSString *humanReadableDescription;

/**
 E.g.: https://circulation.librarysimplified.org/NYNYPL/search/?entrypoint=All&q={searchTerms}
 */
@property (nonatomic, readonly) NSString *OPDSURLTemplate;
@property (nonatomic, readonly) NSArray *books;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (void)withURL:(NSURL *)URL
shouldResetCache:(BOOL)shouldResetCache
completionHandler:(void (^)(NYPLOpenSearchDescription *description))handler;

- (instancetype)initWithXML:(NYPLXML *)OSDXML;

// For local search
- (instancetype)initWithTitle:(NSString *)title books:(NSArray *)books;

/**
 Uses the @p OPDSURLTemplate to create a URL with the given search terms.
 @returns A new URL containing a URL-escaped search string as a query param.
 */
- (NSURL *)OPDSURLForSearchingString:(NSString *)searchString;

@end
