#import "SMXMLDocument.h"

@interface SMXMLElement (NYPLElementAdditions)

// like 'value', but read-only and returns |@""| instead of |nil| for empty elements
@property (nonatomic, readonly) NSString *valueString;

@end
