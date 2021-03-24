#import "NYPLOPDSIndirectAcquisition.h"

#import "NYPLXML.h"
#import "SimplyE-Swift.h"

#pragma mark Dictionary Keys

static NSString *const NYPLOPDSIndirectAcquisitionTypeKey = @"type";

static NSString *const NYPLOPDSIndirectAcquisitionIndirectAcqusitionsKey = @"indirectAcquisitions";

#pragma mark -

@interface NYPLOPDSIndirectAcquisition ()

@property (nonatomic, copy, nonnull) NSString *type;
@property (nonatomic, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

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

+ (_Nullable instancetype)indirectAcquisitionWithDictionary:(NSDictionary *const _Nonnull)dictionary
{
  NSString *const type = dictionary[NYPLOPDSIndirectAcquisitionTypeKey];
  if (![type isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSDictionary *const indirectAcquisitionDictionaries = dictionary[NYPLOPDSIndirectAcquisitionIndirectAcqusitionsKey];
  if (![indirectAcquisitionDictionaries isKindOfClass:[NSArray class]]) {
    return nil;
  }

  NSMutableArray *const mutableIndirectAcquisitions =
    [NSMutableArray arrayWithCapacity:indirectAcquisitionDictionaries.count];

  for (NSDictionary *const indirectAcquisitionDictionary in indirectAcquisitionDictionaries) {
    if (![indirectAcquisitionDictionary isKindOfClass:[NSDictionary class]]) {
      return nil;
    }

    NYPLOPDSIndirectAcquisition *const indirectAcquisition =
    [NYPLOPDSIndirectAcquisition indirectAcquisitionWithDictionary:indirectAcquisitionDictionary];
    if (!indirectAcquisition) {
      return nil;
    }

    [mutableIndirectAcquisitions addObject:indirectAcquisition];
  }

  return [self indirectAcquisitionWithType:type
                      indirectAcquisitions:[mutableIndirectAcquisitions copy]];
}

- (NSDictionary *_Nonnull)dictionaryRepresentation
{
  NSMutableArray *const mutableIndirectionAcqusitionDictionaries =
    [NSMutableArray arrayWithCapacity:self.indirectAcquisitions.count];

  for (NYPLOPDSIndirectAcquisition *const indirectAcqusition in self.indirectAcquisitions) {
    [mutableIndirectionAcqusitionDictionaries addObject:[indirectAcqusition dictionaryRepresentation]];
  }

  return @{
    NYPLOPDSIndirectAcquisitionTypeKey: self.type,
    NYPLOPDSIndirectAcquisitionIndirectAcqusitionsKey: [mutableIndirectionAcqusitionDictionaries copy]
  };
}

@end
