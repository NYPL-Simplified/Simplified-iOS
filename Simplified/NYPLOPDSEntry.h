@import Foundation;

#import <SMXMLDocument/SMXMLDocument.h>

@interface NYPLOPDSEntry : NSObject

// |authorNames| contains |NSString| objects
// |links| contains |NYPLOPDSLink| objects
@property (nonatomic, readonly) NSArray *authorNames;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

// designated initializer
- (id)initWithElement:(SMXMLElement *)element;

@end
