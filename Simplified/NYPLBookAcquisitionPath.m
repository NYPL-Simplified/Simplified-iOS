#import "NYPLOPDSIndirectAcquisition.h"

#import "NYPLBookAcquisitionPath.h"

NSString * const _Nonnull ContentTypeOPDSCatalog = @"application/atom+xml;type=entry;profile=opds-catalog";
NSString * const _Nonnull ContentTypeAdobeAdept = @"application/vnd.adobe.adept+xml";
NSString * const _Nonnull ContentTypeBearerToken = @"application/vnd.librarysimplified.bearer-token+json";
NSString * const _Nonnull ContentTypeEpubZip = @"application/epub+zip";
NSString * const _Nonnull ContentTypeFindaway = @"application/vnd.librarysimplified.findaway.license+json";
NSString * const _Nonnull ContentTypeOpenAccessAudiobook = @"application/audiobook+json";
NSString * const _Nonnull ContentTypeOpenAccessPDF = @"application/pdf";
NSString * const _Nonnull ContentTypeFeedbooksAudiobook = @"application/audiobook+json;profile=\"http://www.feedbooks.com/audiobooks/access-restriction\"";
NSString * const _Nonnull ContentTypeOctetStream = @"application/octet-stream";
NSString * const _Nonnull ContentTypeOverdriveAudiobook = @"application/vnd.overdrive.circulation.api+json;profile=audiobook";
NSString * const _Nonnull ContentTypeOverdriveAudiobookActual = @"application/json";
NSString * const _Nonnull ContentTypeReadiumLCP = @"application/vnd.readium.lcp.license.v1.0+json";
NSString * const _Nonnull ContentTypeAudiobookZip = @"application/audiobook+zip";

@interface NYPLBookAcquisitionPath ()

@property (nonatomic) NYPLOPDSAcquisitionRelation relation;
@property (nonatomic, nonnull) NSArray<NSString *> *types;
@property (nonatomic, nonnull) NSURL *url;

@end

@implementation NYPLBookAcquisitionPath : NSObject

- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation const)relation
                                    types:(NSArray<NSString *> *const _Nonnull)types
                                      url:(NSURL *const _Nonnull)url
{
  self = [super init];

  self.relation = relation;
  self.types = types;
  self.url = url;

  return self;
}

+ (NSSet<NSString *> *_Nonnull)supportedTypes
{
  static NSSet<NSString *> *types = nil;

  if (!types) {
    types = [NSSet setWithArray:@[
      ContentTypeOPDSCatalog,
      ContentTypeAdobeAdept,
      ContentTypeBearerToken,
      ContentTypeEpubZip,
      ContentTypeFindaway,
      ContentTypeOpenAccessAudiobook,
      ContentTypeOpenAccessPDF,
      ContentTypeFeedbooksAudiobook,
      ContentTypeOverdriveAudiobook,
      ContentTypeOctetStream,
      ContentTypeReadiumLCP,
      ContentTypeAudiobookZip
    ]];
  }

  return types;
}
  
+ (NSSet<NSString *> *_Nonnull)supportedSubtypesForType:(NSString *)type
{
  static NSDictionary<NSString *, NSSet<NSString *> *> *subtypesForTypes = nil;
  
  if (!subtypesForTypes) {
    subtypesForTypes = @{
      ContentTypeOPDSCatalog: [NSSet setWithArray:@[
        ContentTypeAdobeAdept,
        ContentTypeBearerToken,
        ContentTypeFindaway,
        ContentTypeEpubZip,
        ContentTypeOpenAccessPDF,
        ContentTypeOpenAccessAudiobook,
        ContentTypeFeedbooksAudiobook,
        ContentTypeOverdriveAudiobook,
        ContentTypeOctetStream,
        ContentTypeReadiumLCP,
        ContentTypeAudiobookZip
      ]],
      ContentTypeReadiumLCP: [NSSet setWithArray:@[
          ContentTypeBearerToken,
          ContentTypeEpubZip,
          ContentTypeAudiobookZip
      ]],
      ContentTypeAdobeAdept: [NSSet setWithArray:@[ContentTypeEpubZip]],
      ContentTypeBearerToken: [NSSet setWithArray:@[
        ContentTypeEpubZip,
        ContentTypeOpenAccessPDF,
        ContentTypeOpenAccessAudiobook
      ]]
    };
  }
  
  NSSet<NSString *> *types = subtypesForTypes[type];
  
  return types ?: [NSSet set];
}

+ (NSSet<NSString *> *_Nonnull)audiobookTypes {
  return [NSSet setWithArray:@[ContentTypeFindaway,
                               ContentTypeOpenAccessAudiobook,
                               ContentTypeFeedbooksAudiobook,
                               ContentTypeOverdriveAudiobook,
                               ContentTypeAudiobookZip ]];
}

- (BOOL)isEqual:(id const)object
{
  if (![object isKindOfClass:[NYPLBookAcquisitionPath class]]) {
    return NO;
  }

  NYPLBookAcquisitionPath *const path = object;

  return self.relation == path.relation && [self.types isEqualToArray:path.types];
}

- (NSUInteger)hash
{
  NSUInteger const prime = 31;
  NSUInteger result = 1;

  result = prime * result + self.relation;
  result = prime * result + [self.types hash];

  return result;
}

NSMutableArray<NSMutableArray<NSString *> *> *_Nonnull
mutableTypePaths(
  NYPLOPDSIndirectAcquisition *const _Nonnull indirectAcquisition,
  NSSet<NSString *> *const _Nonnull allowedTypes)
{
  if ([allowedTypes containsObject:indirectAcquisition.type]) {
    if (indirectAcquisition.indirectAcquisitions.count == 0) {
      return [NSMutableArray arrayWithObject:[NSMutableArray arrayWithObject:indirectAcquisition.type]];
    } else {
      NSMutableSet<NSString *> *supportedSubtypes = [[NYPLBookAcquisitionPath supportedSubtypesForType:indirectAcquisition.type] mutableCopy];
      [supportedSubtypes intersectSet:allowedTypes];
      NSMutableArray<NSMutableArray<NSString *> *> *const mutableTypePathsResults = [NSMutableArray array];
      for (NYPLOPDSIndirectAcquisition *const nestedIndirectAcquisition in indirectAcquisition.indirectAcquisitions) {
        if (![supportedSubtypes containsObject:nestedIndirectAcquisition.type]) {
          continue;
        }
        for (NSMutableArray<NSString *> *const mutableTypePath
             in mutableTypePaths(nestedIndirectAcquisition, allowedTypes))
        {
          // This operation is not O(1) as desired but it is close enough for our purposes.
          [mutableTypePath insertObject:indirectAcquisition.type atIndex:0];
          [mutableTypePathsResults addObject:mutableTypePath];
        }
      }
      return mutableTypePathsResults;
    }
  } else {
    return [NSMutableArray array];
  }
}


+ (NSArray<NYPLBookAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NSArray<NYPLOPDSAcquisition *> *_Nonnull)acquisitions
{
  NSMutableSet *const mutableAcquisitionPathSet = [NSMutableSet set];
  NSMutableArray *const mutableAcquisitionPaths = [NSMutableArray array];

  for (NYPLOPDSAcquisition *const acquisition in acquisitions) {
    if ([types containsObject:acquisition.type]
        && NYPLOPDSAcquisitionRelationSetContainsRelation(relations, acquisition.relation))
    {
      if (acquisition.indirectAcquisitions.count == 0) {
        [mutableAcquisitionPaths addObject:
         [[NYPLBookAcquisitionPath alloc]
          initWithRelation:acquisition.relation
          types:@[acquisition.type]
          url:acquisition.hrefURL]];
      } else {
        NSMutableSet<NSString *> *supportedSubtypes = [[NYPLBookAcquisitionPath supportedSubtypesForType:acquisition.type] mutableCopy];
        [supportedSubtypes intersectSet:types];
        for (NYPLOPDSIndirectAcquisition *const indirectAcquisition in acquisition.indirectAcquisitions) {
          if (![supportedSubtypes containsObject:indirectAcquisition.type]) {
            continue;
          }
          for (NSMutableArray<NSString *> *const mutableTypePath in mutableTypePaths(indirectAcquisition, types)) {
            [mutableTypePath insertObject:acquisition.type atIndex:0];
            NYPLBookAcquisitionPath *const acquisitionPath =
            [[NYPLBookAcquisitionPath alloc]
             initWithRelation:acquisition.relation
             types:[mutableTypePath copy]
             url:acquisition.hrefURL];
            if (![mutableAcquisitionPathSet containsObject:acquisitionPath]) {
              [mutableAcquisitionPaths addObject:acquisitionPath];
              [mutableAcquisitionPathSet addObject:acquisitionPath];
            }
          }
        }
      }
    }
  }

  return [mutableAcquisitionPaths copy];
}

@end
