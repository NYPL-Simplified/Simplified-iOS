#import "NSDate+NYPLDateAdditions.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"

#import "NYPLOPDSLink.h"

@interface NYPLOPDSLink ()

@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSURL *href;
@property (nonatomic) NSString *rel;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *hreflang;
@property (nonatomic) NSString *title;

@end

@implementation NYPLOPDSLink

- (instancetype)initWithXML:(NYPLXML *const)linkXML
{
  self = [super init];
  if(!self) return nil;
  
  {
    NSString *const hrefString = linkXML.attributes[@"href"];
    if(!hrefString) {
      NYPLLOG(@"Missing required 'href' attribute.");
      return nil;
    }
    
    if(!((self.href = [NSURL URLWithString:hrefString]))) {
      // Atom requires support for RFC 3986, but CFURL and NSURL only support RFC 2396. As such, a
      // valid URI may be rejected in extremely rare cases.
      NYPLLOG(@"'href' attribute does not contain an RFC 2396 URI.");
      return nil;
    }
  }
  
  self.attributes = linkXML.attributes;
  self.rel = linkXML.attributes[@"rel"];
  self.type = linkXML.attributes[@"type"];
  self.hreflang = linkXML.attributes[@"hreflang"];
  self.title = linkXML.attributes[@"title"];

  return self;
}

@end
