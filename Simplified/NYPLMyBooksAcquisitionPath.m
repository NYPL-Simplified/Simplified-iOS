#import "NYPLOPDSIndirectAcquisition.h"

#import "NYPLMyBooksAcquisitionPath.h"

@interface NYPLMyBooksAcquisitionPath ()

@property (nonatomic) NYPLOPDSAcquisitionRelation relation;
@property (nonatomic, nonnull) NSArray<NSString *> *types;

@end

@implementation NYPLMyBooksAcquisitionPath : NSObject

- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation const)relation
                                    types:(NSArray<NSString *> *const _Nonnull)types
{
  self = [super init];

  self.relation = relation;
  self.types = types;

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

NSMutableArray<NSMutableArray<NSString *> *> *_Nonnull
mutableTypePaths(
  NYPLOPDSIndirectAcquisition *const _Nonnull indirectAcquisition,
  NSSet<NSString *> *const _Nonnull allowedTypes)
{
  if ([allowedTypes containsObject:indirectAcquisition.type]) {
    NSMutableArray<NSMutableArray<NSString *> *> *const mutableTypePathResults = [NSMutableArray array];
    for (NYPLOPDSIndirectAcquisition *const nestedIndirectAcquisition in indirectAcquisition.indirectAcquisitions) {
      NSMutableArray<NSMutableArray<NSString *> *> *const mutableTypePathResult =
        mutableTypePaths(nestedIndirectAcquisition, allowedTypes);
      [mutableTypePathResults addObjectsFromArray:mutableTypePathResult];
    }
    return mutableTypePathResults;
  } else {
    return [NSMutableArray array];
  }
}


+ (NSOrderedSet<NYPLMyBooksAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NSArray<NYPLOPDSAcquisition *> *_Nonnull)acquisitions
{
  NSMutableOrderedSet *const mutableAcquisitionPaths = [NSMutableOrderedSet orderedSet];

  for (NYPLOPDSAcquisition *const acquisition in acquisitions) {
    // `acquisition.relation & relations` checks set membership. The use of bitwise-AND
    // is intentional.
    if ([types containsObject:acquisition.type] && (acquisition.relation & relations)) {
      for (NYPLOPDSIndirectAcquisition *const indirectAcquisition in acquisition.indirectAcquisitions) {
        for (NSMutableArray<NSString *> *const mutableTypePath in mutableTypePaths(indirectAcquisition, types)) {
          NYPLMyBooksAcquisitionPath *const acquisitionPath =
            [[NYPLMyBooksAcquisitionPath alloc] initWithRelation:acquisition.relation types:[mutableTypePath copy]];
          [mutableAcquisitionPaths addObject:acquisitionPath];
        }
      }
    }
  }

  return [mutableAcquisitionPaths copy];
}

@end
