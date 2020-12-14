#import "NSDate+NYPLDateAdditions.h"
#import "NYPLAsync.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLSession.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"
#import "NYPLOPDSFeed.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@interface NYPLOPDSFeed ()

@property (nonatomic) NSArray *entries;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *title;
@property (nonatomic) NYPLOPDSFeedType type;
@property (nonatomic) BOOL typeIsCached;
@property (nonatomic) NSDate *updated;
@property (nonatomic) NSMutableDictionary *licensor;
@property (nonatomic) NSString *authorizationIdentifier;

@end

static NYPLOPDSFeedType TypeImpliedByEntry(NYPLOPDSEntry *const entry)
{
  BOOL entryIsGrouped = NO;

  // NOTE: A catalog entry is an acquisition feed according to section 8 of
  // OPDS Catalog 1.1 if it contains at least one acquisition link.
  BOOL entryIsCatalogEntry = entry.acquisitions.count >= 1;

  for(NYPLOPDSLink *const link in entry.links) {
    if([link.rel hasPrefix:@"http://opds-spec.org/acquisition"]) {
      // This also means we have an acquisition feed.
      entryIsCatalogEntry = YES;
    } else if([link.rel isEqualToString:NYPLOPDSRelationGroup]) {
      entryIsGrouped = YES;
    }
  }
  
  if(entryIsGrouped && !entryIsCatalogEntry) {
    return NYPLOPDSFeedTypeInvalid;
  }
  
  return (entryIsCatalogEntry
          ? (entryIsGrouped
             ? NYPLOPDSFeedTypeAcquisitionGrouped
             : NYPLOPDSFeedTypeAcquisitionUngrouped)
          : NYPLOPDSFeedTypeNavigation);
}

@implementation NYPLOPDSFeed

+ (void)withURL:(NSURL *)URL
shouldResetCache:(BOOL)shouldResetCache
completionHandler:(void (^)(NYPLOPDSFeed *feed, NSDictionary *error))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }

  __block NSURLRequest *request = nil;
  NSURLRequestCachePolicy cachePolicy;
  if (shouldResetCache) {
    cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  } else {
    cachePolicy = NSURLRequestUseProtocolCachePolicy;
  }

  if (URL == nil) {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                              summary:@"NYPLOPDSFeed: nil URL"
                              message:nil
                             metadata:@{
                               @"shouldResetCache": @(shouldResetCache)
                             }];
    NYPLAsyncDispatch(^{handler(nil, nil);});
    return;
  }

  request = [[[NYPLNetworkExecutor shared] GET:URL
                                   cachePolicy:cachePolicy
                                    completion:^(NSData *data, NSURLResponse *response, NSError *error) {

    if (error != nil) {
      // Note: NYPLNetworkExecutor already logged this error
      NYPLAsyncDispatch(^{handler(nil, error.problemDocument.dictionaryValue);});
      return;
    }

    if (data == nil) {
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeOpdsFeedNoData
                                summary:@"NYPLOPDSFeed: no data from server"
                                message:nil
                               metadata:@{
                                 @"Request": [request loggableString],
                                 @"Response": response ?: @"N/A",
                               }];
      NYPLAsyncDispatch(^{handler(nil, nil);});
      return;
    }

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
      NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;

      if (httpResp.statusCode < 200 || httpResp.statusCode > 299) {
        // this captures a situation where (e.g.) borrow requests to the
        // Brooklyn lib come back with a 500 status code, no error, and non-nil
        // data containing "An internal error occurred" plain text.
        NSString *msg = [NSString stringWithFormat:@"Got %ld HTTP status with no error object.", (long)httpResp.statusCode];

        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSDictionary *problemDocDict = nil;
        if (response.isProblemDocument) {
          problemDocDict = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
        }

        [NYPLErrorLogger logNetworkError:error
                                    code:NYPLErrorCodeApiCall
                                 summary:@"NYPLOPDSFeed: HTTP response error"
                                 request:request
                                response:response
                                 message:msg
                                metadata:@{
                                  @"receivedData": dataString ?: @"N/A",
                                  @"receivedDataLength (bytes)": @(data.length),
                                  @"problemDoc": problemDocDict ?: @"N/A"
                                }];

        NYPLAsyncDispatch(^{handler(nil, problemDocDict);});
        return;
      }
    }
    
    NYPLXML *const feedXML = [NYPLXML XMLWithData:data];
    if(!feedXML) {
      NYPLLOG(@"Failed to parse data as XML.");
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeFeedParseFail
                                summary:@"NYPLOPDSFeed: Failed to parse data as XML"
                                message:@"Error in NYPLOPDSFeed::withURL:"
                               metadata:@{
                                 @"request": request.loggableString,
                                 @"response": response ?: @"N/A",
                               }];
      // this error may be nil
      NSDictionary *error = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
      NYPLAsyncDispatch(^{handler(nil, error);});
      return;
    }
    
    NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:feedXML];
    if(!feed) {
      NYPLLOG(@"Could not interpret XML as OPDS.");
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeOpdsFeedParseFail
                                summary:@"NYPLOPDSFeed: Failed to parse XML as OPDS"
                                message:@"Error in NYPLOPDSFeed::withURL:"
                               metadata:@{
                                 @"request": request.loggableString,
                                 @"response": response ?: @"N/A",
                               }];
      NYPLAsyncDispatch(^{handler(nil, nil);});
      return;
    }
    
    NYPLAsyncDispatch(^{handler(feed, nil);});
  }] originalRequest];
}

- (instancetype)initWithXML:(NYPLXML *const)feedXML
{
  self = [super init];
  if(!self) return nil;
  
  if(!feedXML) {
    return nil;
  }
  
  // Sometimes we get back JUST an entry, and in that case we just want to construct a feed with
  // nothing set other than the entry.
  if ([feedXML.name isEqual:@"entry"]) {
    NYPLOPDSEntry const* entry = [[NYPLOPDSEntry alloc] initWithXML:feedXML];
    if (entry) {
      self.entries = @[entry];
      return self;
    } else {
      NYPLLOG(@"Error creating single OPDS entry from feed.");
      return nil;
    }
  }
  
  if(!((self.identifier = [feedXML firstChildWithName:@"id"].value))) {
    NYPLLOG(@"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(NYPLXML *const linkXML in [feedXML childrenWithName:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  if(!((self.title = [feedXML firstChildWithName:@"title"].value))) {
    NYPLLOG(@"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [feedXML firstChildWithName:@"updated"].value;
    if(!updatedString) {
      NYPLLOG(@"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339String:updatedString];
    if(!self.updated) {
      NYPLLOG(@"Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }
  
  {
    NSMutableArray *const entries = [NSMutableArray array];
    
    for(NYPLXML *const entryXML in [feedXML childrenWithName:@"entry"]) {
      NYPLOPDSEntry *const entry = [[NYPLOPDSEntry alloc] initWithXML:entryXML];
      if(!entry) {
        NYPLLOG(@"Ingoring malformed 'entry' element.");
        continue;
      }
      [entries addObject:entry];
    }
    
    self.entries = entries;
  }
  
  {
    NYPLXML *patronXML = [feedXML firstChildWithName:@"patron"];
    if (patronXML && patronXML.attributes.allValues.count>0) {
      NSString *barcode = patronXML.attributes[@"simplified:authorizationIdentifier"];
      self.authorizationIdentifier = barcode;
    }
  }
  
  {
    NYPLXML *licensorXML = [feedXML firstChildWithName:@"licensor"];
    if (licensorXML && licensorXML.attributes.allValues.count>0) {
      NSString *vendor = licensorXML.attributes[@"drm:vendor"];
      NYPLXML *tokenXML = [licensorXML firstChildWithName:@"clientToken"];
      
      if (tokenXML) {
        NSString *clientToken = tokenXML.value;
        self.licensor = @{@"vendor":vendor,
                          @"clientToken":clientToken}.mutableCopy;
      } else {
        NYPLLOG(@"Licensor not saved. Error parsing clientToken into XML.");
      }
    } else {
      NYPLLOG(@"No Licensor found in OPDS feed. Moving on.");
    }
  }
  
  return self;
}

- (NYPLOPDSFeedType)type
{
  if(self.typeIsCached) {
    return _type;
  }
  
  self.typeIsCached = YES;
  
  if(self.entries.count == 0) {
    _type = NYPLOPDSFeedTypeAcquisitionUngrouped;
    return _type;
  }
  
  NYPLOPDSFeedType const provisionalType = TypeImpliedByEntry(self.entries.firstObject);
  
  if(provisionalType == NYPLOPDSFeedTypeInvalid) {
    _type = NYPLOPDSFeedTypeInvalid;
    return _type;
  }
  
  for(unsigned int i = 1; i < self.entries.count; ++i) {
    if(TypeImpliedByEntry(self.entries[i]) != provisionalType) {
      _type = NYPLOPDSFeedTypeInvalid;
      return _type;
    }
  }
  
  _type = provisionalType;
  return _type;
}

@end
