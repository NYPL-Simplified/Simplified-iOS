#import "NYPLAsync.h"
#import "NYPLSession.h"
#import "NYPLXML.h"

#import "NYPLOpenSearchDescription.h"

@interface NYPLOpenSearchDescription ()

@property (nonatomic) NSString *OPDSURLTemplate;

@end

@implementation NYPLOpenSearchDescription

+ (void)withURL:(NSURL *const)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *))handler
{
  [[NYPLSession sharedSession]
   withURL:URL
   completionHandler:^(NSData *const data) {
     if(!data) {
       NYPLLOG(@"Failed to retrieve data.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLXML *const XML = [NYPLXML XMLWithData:data];
     if(!XML) {
       NYPLLOG(@"Failed to parse data as XML.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLOpenSearchDescription *const description =
       [[NYPLOpenSearchDescription alloc] initWithXML:XML];
     
     if(!description) {
       NYPLLOG(@"Failed to interpret XML as OpenSearch description document.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLAsyncDispatch(^{handler(description);});
   }];
}

- (instancetype)initWithXML:(NYPLXML *const)OSDXML
{
  self = [super init];
  if(!self) return nil;
  
  for(NYPLXML *const UrlXML in [OSDXML childrenWithName:@"Url"]) {
    NSString *const type = UrlXML.attributes[@"type"];
    if(type && [type rangeOfString:@"opds-catalog"].location != NSNotFound) {
      self.OPDSURLTemplate = UrlXML.attributes[@"template"];
      break;
    }
  }
  
  return self;
}

@end
