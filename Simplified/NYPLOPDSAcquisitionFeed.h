#import <Foundation/Foundation.h>
#import <SMXMLDocument/SMXMLDocument.h>

@interface NYPLOPDSAcquisitionFeed : NSObject

// designated initializer
- (id)initWithDocument:(SMXMLDocument *)document;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

@end
