#import "NYPLOPDSLink.h"

@interface NYPLOPDSLink ()

@property (nonatomic) NSURL *href;
@property (nonatomic) NSString *rel;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *hreflang;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *length;

@end

@implementation NYPLOPDSLink

- (id)initWithElement:(SMXMLElement *const)element
{
  self = [super init];
  if(!self) return nil;
  
  {
    NSString *const hrefString = [element attributeNamed:@"href"];
    if(!hrefString) {
      NSLog(@"NYPLOPDSLink: Missing required 'href' attribute.");
      return nil;
    }
    
    if(!((self.href = [NSURL URLWithString:hrefString]))) {
      // Atom requires support for RFC 3986, but CFURL and NSURL only support RFC 2396. As such, a
      // valid URI may be rejected in extremely rare cases.
      NSLog(@"NYPLOPDSLink: 'href' attribute does not contain an RFC 2396 URI.");
      return nil;
    }
  }
  
  self.rel = [element attributeNamed:@"rel"];
  self.type = [element attributeNamed:@"type"];
  self.hreflang = [element attributeNamed:@"hreflang"];
  self.title = [element attributeNamed:@"title"];
  self.length = [element attributeNamed:@"length"];
  
  return self;
}

@end
