@import Foundation;

#import <SMXMLDocument/SMXMLDocument.h>

@interface NYPLOPDSFeed : NSObject

@property (nonatomic, readonly) NSArray *entries;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

// designated initializer
- (id)initWithDocument:(SMXMLDocument *)document;

@end
