#import "NYPLOPDSLink.h"

@interface NYPLOPDSLink ()

@property (nonatomic) NSString *href;
@property (nonatomic) NSString *rel;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *hreflang;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *length;

@end

@implementation NYPLOPDSLink

- (id)initWithElement:(SMXMLElement *)element
{
  self = [super init];
  if(!self) return nil;
  
  self.href = [element attributeNamed:@"href"];
  if(!self.href) {
    NSLog(@"NYPLOPDSLink: Missing required 'href' attribute.");
    return nil;
  }
  
  self.rel = [element attributeNamed:@"rel"];
  self.type = [element attributeNamed:@"type"];
  self.hreflang = [element attributeNamed:@"hreflang"];
  self.title = [element attributeNamed:@"title"];
  self.length = [element attributeNamed:@"length"];
  
  return self;
}

@end
