#import "NYPLOPDSIndirectAcquisition.h"

@interface NYPLOPDSIndirectAcquisition ()

@property (copy, nonnull) NSString *type;
@property (nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

@end

@implementation NYPLOPDSIndirectAcquisition

+ (instancetype _Nonnull)
indirectAcquisitionWithType:(NSString *const _Nonnull)type
indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcquisitions
{
  return [[self alloc] initWithType:type indirectAcquisitions:indirectAcquisitions];
}

- (instancetype _Nonnull)initWithType:(NSString *const _Nonnull)type
                 indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcquisitions
{
  self = [super init];

  self.type = type;
  self.indirectAcquisitions = indirectAcquisitions;

  return self;
}

@end
