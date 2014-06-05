#import <Foundation/Foundation.h>
#import <SMXMLDocument/SMXMLDocument.h>

@interface NYPLOPDSLink : NSObject

@property (nonatomic, readonly) NSString *href;
@property (nonatomic, readonly) NSString *rel;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *hreflang;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *length;

// designated initializer
- (id)initWithElement:(SMXMLElement *)element;

@end
