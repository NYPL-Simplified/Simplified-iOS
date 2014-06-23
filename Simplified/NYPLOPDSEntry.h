#import <SMXMLDocument/SMXMLDocument.h>

@interface NYPLOPDSEntry : NSObject

@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

// designated initializer
- (instancetype)initWithElement:(SMXMLElement *)element;

@end
