#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsync.h"
#import "NYPLSession.h"

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
     
     SMXMLDocument *const document = [SMXMLDocument documentWithData:data error:NULL];
     if(!document) {
       NYPLLOG(@"Failed to parse data as XML.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLOpenSearchDescription *const description =
       [[NYPLOpenSearchDescription alloc] initWithDocument:document];
     
     if(!description) {
       NYPLLOG(@"Failed to interpret XML as OpenSearch description document.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLAsyncDispatch(^{handler(description);});
   }];
}

- (instancetype)initWithDocument:(SMXMLDocument *const)document
{
  self = [super init];
  if(!self) return nil;
  
  for(SMXMLElement *const element in [document.root childrenNamed:@"Url"]) {
    NSString *const type = [element attributeNamed:@"type"];
    if(type && [type rangeOfString:@"opds-catalog"].location != NSNotFound) {
      self.OPDSURLTemplate = [element attributeNamed:@"template"];
      break;
    }
  }
  
  return self;
}

@end
