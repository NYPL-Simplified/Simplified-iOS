#import "NYPLOPDSIndirectAcquisition.h"

#import "NYPLXML.h"

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

+ (instancetype _Nullable)indirectAcquisitionWithXML:(NYPLXML *const _Nonnull)xml
{
  NSString *const type = [xml attributes][@"type"];
  if (!type) {
    return nil;
  }

  NSMutableArray<NYPLOPDSIndirectAcquisition *> *const mutableIndirectAcquisitions = [NSMutableArray array];
  for (NYPLXML *const indirectAcquisitionXML in [xml childrenWithName:@"indirectAcquisition"]) {
    NYPLOPDSIndirectAcquisition *const indirectAcquisition =
      [NYPLOPDSIndirectAcquisition indirectAcquisitionWithXML:indirectAcquisitionXML];

    if (indirectAcquisition) {
      [mutableIndirectAcquisitions addObject:indirectAcquisition];
    } else {
      NYPLLOG(@"Ignoring invalid indirect acquisition.");
    }
  }

  return [self indirectAcquisitionWithType:type
                      indirectAcquisitions:[mutableIndirectAcquisitions copy]];
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
