#import "NYPLAsync.h"
#import "NYPLSession.h"
#import "NYPLXML.h"

#import "NYPLOpenSearchDescription.h"

@interface NYPLOpenSearchDescription ()

@property (nonatomic) NSString *humanReadableDescription;
@property (nonatomic) NSString *OPDSURLTemplate;
@property (nonatomic) NSArray *books;

@end

@implementation NYPLOpenSearchDescription

+ (void)withURL:(NSURL *const)URL
completionHandler:(void (^)(NYPLOpenSearchDescription *))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLSession sharedSession]
   withURL:URL
   completionHandler:^(NSData *const data, __unused NSURLResponse *response, __unused NSError *error) {
     if(!data) {
       NYPLLOG(@"Failed to retrieve data.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     NYPLXML *const XML = [NYPLXML XMLWithData:data];
//     NSString *datcat = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] substringToIndex:100];
//     NSDictionary *errData = @{@"data": [NSString stringWithFormat:@"%@...", datcat]};
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
  
  self.humanReadableDescription = [OSDXML firstChildWithName:@"Description"].value;
  
  if(!self.humanReadableDescription) {
    NYPLLOG(@"Missing required description element.");
    return nil;
  }
  
  for(NYPLXML *const UrlXML in [OSDXML childrenWithName:@"Url"]) {
    NSString *const type = UrlXML.attributes[@"type"];
    if(type && [type rangeOfString:@"opds-catalog"].location != NSNotFound) {
      self.OPDSURLTemplate = UrlXML.attributes[@"template"];
      break;
    }
  }
  
  if(!self.OPDSURLTemplate) {
    NYPLLOG(@"Missing expected OPDS URL.");
    return nil;
  }
  
  return self;
}

- (instancetype)initWithTitle:(NSString *)title books:(NSArray *)books
{
  self = [super init];
  if(!self) return nil;
  self.books = books;
  self.humanReadableDescription = title;
  return self;
}

@end
