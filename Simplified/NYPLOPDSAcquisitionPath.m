#import "NYPLOPDSIndirectAcquisition.h"

#import "NYPLOPDSAcquisitionPath.h"

@interface NYPLOPDSAcquisitionPath ()

@property (nonatomic) NYPLOPDSAcquisitionRelation relation;
@property (nonatomic, nonnull) NSArray<NSString *> *types;
@property (nonatomic, nonnull) NSURL *url;

@end

@implementation NYPLOPDSAcquisitionPath : NSObject

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
      @"application/atom+xml;type=entry;profile=opds-catalog",
      @"application/vnd.adobe.adept+xml",
      @"application/epub+zip"
    ]];
  }

  return types;
}

- (BOOL)isEqual:(id const)object
{
  if (![object isKindOfClass:[NYPLOPDSAcquisitionPath class]]) {
    return NO;
  }

  NYPLOPDSAcquisitionPath *const path = object;

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
      NSMutableArray<NSMutableArray<NSString *> *> *const mutableTypePathsResults = [NSMutableArray array];
      for (NYPLOPDSIndirectAcquisition *const nestedIndirectAcquisition in indirectAcquisition.indirectAcquisitions) {
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


+ (NSSet<NYPLOPDSAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NSArray<NYPLOPDSAcquisition *> *_Nonnull)acquisitions
{
  NSMutableSet *const mutableAcquisitionPaths = [NSMutableSet set];

  for (NYPLOPDSAcquisition *const acquisition in acquisitions) {
    if ([types containsObject:acquisition.type]
        && NYPLOPDSAcquisitionRelationSetContainsRelation(relations, acquisition.relation))
    {
      if (acquisition.indirectAcquisitions.count == 0) {
        [mutableAcquisitionPaths addObject:
         [[NYPLOPDSAcquisitionPath alloc]
          initWithRelation:acquisition.relation
          types:@[acquisition.type]
          url:acquisition.hrefURL]];
      } else {
        for (NYPLOPDSIndirectAcquisition *const indirectAcquisition in acquisition.indirectAcquisitions) {
          for (NSMutableArray<NSString *> *const mutableTypePath in mutableTypePaths(indirectAcquisition, types)) {
            [mutableTypePath insertObject:acquisition.type atIndex:0];
            NYPLOPDSAcquisitionPath *const acquisitionPath =
            [[NYPLOPDSAcquisitionPath alloc]
             initWithRelation:acquisition.relation
             types:[mutableTypePath copy]
             url:acquisition.hrefURL];
            [mutableAcquisitionPaths addObject:acquisitionPath];
          }
        }
      }
    }
  }

  return [mutableAcquisitionPaths copy];
}

@end
