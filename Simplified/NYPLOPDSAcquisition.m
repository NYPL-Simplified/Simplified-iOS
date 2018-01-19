#import "NYPLOPDSAcquisition.h"

#import "NYPLOPDSIndirectAcquisition.h"
#import "NYPLXML.h"

#pragma mark OPDS Acqusition Relations

static NSString *const NYPLOPDSAcquisitionRelationGenericString =
  @"http://opds-spec.org/acquisition";

static NSString *const NYPLOPDSAcquisitionRelationOpenAccessString =
  @"http://opds-spec.org/acquisition/open-access";

static NSString *const NYPLOPDSAcquisitionRelationBorrowString =
  @"http://opds-spec.org/acquisition/borrow";

static NSString *const NYPLOPDSAcquisitionRelationBuyString =
  @"http://opds-spec.org/acquisition/buy";

static NSString *const NYPLOPDSAcquisitionRelationSampleString =
  @"http://opds-spec.org/acquisition/sample";

static NSString *const NYPLOPDSAcquisitionRelationSubscribeString =
  @"http://opds-spec.org/acquisition/subscribe";

#pragma mark Dictionary Keys

static NSString *const NYPLOPDSAcquisitionRelationKey = @"rel";

static NSString *const NYPLOPDSAcquisitionTypeKey = @"type";

static NSString *const NYPLOPDSAcquisitionHrefURLKey = @"href";

static NSString *const NYPLOPDSAcquisitionIndirectAcqusitionsKey = @"indirectAcqusitions";

#pragma mark -

static NSUInteger const numberOfRelations = 6;

NYPLOPDSAcquisitionRelationSet const NYPLOPDSAcquisitionRelationSetAll = (1 << (numberOfRelations + 1)) - 1;

NYPLOPDSAcquisitionRelationSet
NYPLOPDSAcquisitionRelationSetWithRelation(NYPLOPDSAcquisitionRelation relation)
{
  switch (relation) {
    case NYPLOPDSAcquisitionRelationBuy:
      return NYPLOPDSAcquisitionRelationSetBuy;
    case NYPLOPDSAcquisitionRelationBorrow:
      return NYPLOPDSAcquisitionRelationSetBorrow;
    case NYPLOPDSAcquisitionRelationSample:
      return NYPLOPDSAcquisitionRelationSetSample;
    case NYPLOPDSAcquisitionRelationGeneric:
      return NYPLOPDSAcquisitionRelationSetGeneric;
    case NYPLOPDSAcquisitionRelationSubscribe:
      return NYPLOPDSAcquisitionRelationSetSubscribe;
    case NYPLOPDSAcquisitionRelationOpenAccess:
      return NYPLOPDSAcquisitionRelationSetOpenAccess;
  }
}

BOOL
NYPLOPDSAcquisitionRelationWithString(NSString *const _Nonnull string,
                                      NYPLOPDSAcquisitionRelation *const _Nonnull relationPointer)
{
  static NSDictionary<NSString *, NSNumber *> *lazyStringToRelationObjectDict = nil;

  if (lazyStringToRelationObjectDict == nil) {
    lazyStringToRelationObjectDict = @{
      NYPLOPDSAcquisitionRelationGenericString: @(NYPLOPDSAcquisitionRelationGeneric),
      NYPLOPDSAcquisitionRelationOpenAccessString: @(NYPLOPDSAcquisitionRelationOpenAccess),
      NYPLOPDSAcquisitionRelationBorrowString: @(NYPLOPDSAcquisitionRelationBorrow),
      NYPLOPDSAcquisitionRelationBuyString: @(NYPLOPDSAcquisitionRelationBuy),
      NYPLOPDSAcquisitionRelationSampleString: @(NYPLOPDSAcquisitionRelationSample),
      NYPLOPDSAcquisitionRelationSubscribeString: @(NYPLOPDSAcquisitionRelationSubscribe)
    };
  }

  NSNumber *const relationObject = lazyStringToRelationObjectDict[string];
  if (!relationObject) {
    return NO;
  }

  *relationPointer = relationObject.integerValue;

  return YES;
}

NSString *_Nonnull
NYPLOPDSAcquisitionRelationString(NYPLOPDSAcquisitionRelation const relation)
{
  switch (relation) {
    case NYPLOPDSAcquisitionRelationGeneric:
      return NYPLOPDSAcquisitionRelationGenericString;
    case NYPLOPDSAcquisitionRelationOpenAccess:
      return NYPLOPDSAcquisitionRelationOpenAccessString;
    case NYPLOPDSAcquisitionRelationBorrow:
      return NYPLOPDSAcquisitionRelationBorrowString;
    case NYPLOPDSAcquisitionRelationBuy:
      return NYPLOPDSAcquisitionRelationBuyString;
    case NYPLOPDSAcquisitionRelationSample:
      return NYPLOPDSAcquisitionRelationSampleString;
    case NYPLOPDSAcquisitionRelationSubscribe:
      return NYPLOPDSAcquisitionRelationSubscribeString;
  }
}

@interface NYPLOPDSAcquisition ()

@property NYPLOPDSAcquisitionRelation relation;
@property (nonatomic, copy, nonnull) NSString *type;
@property (nonatomic, nonnull) NSURL *hrefURL;
@property (nonatomic, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

@end

@implementation NYPLOPDSAcquisition

+ (_Nonnull instancetype)
acquisitionWithRelation:(NYPLOPDSAcquisitionRelation const)relation
type:(NSString *const _Nonnull)type
hrefURL:(NSURL *const _Nonnull)hrefURL
indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcqusitions
{
  return [[self alloc] initWithRelation:relation
                                   type:type
                                hrefURL:hrefURL
                   indirectAcquisitions:indirectAcqusitions];
}

+ (_Nullable instancetype)acquisitionWithXML:(NYPLXML *const _Nonnull)xml
{
  NSString *const relationString = [xml attributes][@"rel"];
  if (!relationString) {
    return nil;
  }

  NYPLOPDSAcquisitionRelation relation;
  if (!NYPLOPDSAcquisitionRelationWithString(relationString, &relation)) {
    return nil;
  }

  NSString *const type = [xml attributes][@"type"];
  if (!type) {
    return nil;
  }

  NSString *const hrefString = [xml attributes][@"href"];
  if (!hrefString) {
    return nil;
  }

  NSURL *const hrefURL = [NSURL URLWithString:hrefString];
  if (!hrefURL) {
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

  return [self acquisitionWithRelation:relation
                                  type:type
                               hrefURL:hrefURL
                  indirectAcquisitions:[mutableIndirectAcquisitions copy]];
}

- (_Nonnull instancetype)initWithRelation:(NYPLOPDSAcquisitionRelation const)relation
                                     type:(NSString *const _Nonnull)type
                                  hrefURL:(NSURL *const _Nonnull)hrefURL
                     indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcqusitions
{
  self = [super init];

  self.relation = relation;
  self.type = type;
  self.hrefURL = hrefURL;
  self.indirectAcquisitions = indirectAcqusitions;

  return self;
}

+ (_Nullable instancetype)acquisitionWithDictionary:(NSDictionary *const _Nonnull)dictionary
{
  NSString *const relationString = dictionary[NYPLOPDSAcquisitionRelationKey];
  if (![relationString isKindOfClass:[NSString class]]) {
    return nil;
  }

  NYPLOPDSAcquisitionRelation relation;
  if (!NYPLOPDSAcquisitionRelationWithString(relationString, &relation)) {
    return nil;
  }

  NSString *const type = dictionary[NYPLOPDSAcquisitionTypeKey];
  if (![type isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSString *const hrefURLString = dictionary[NYPLOPDSAcquisitionHrefURLKey];
  if (![hrefURLString isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSURL *const hrefURL = [NSURL URLWithString:hrefURLString];
  if (!hrefURL) {
    return nil;
  }

  NSDictionary *const indirectAcquisitionDictionaries = dictionary[NYPLOPDSAcquisitionIndirectAcqusitionsKey];
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

  return [NYPLOPDSAcquisition
          acquisitionWithRelation:relation
          type:type
          hrefURL:hrefURL
          indirectAcquisitions:[mutableIndirectAcquisitions copy]];
}

- (NSDictionary *_Nonnull)dictionary
{
  NSMutableArray *const mutableIndirectAcquistionDictionaries =
    [NSMutableArray arrayWithCapacity:self.indirectAcquisitions.count];

  for (NYPLOPDSIndirectAcquisition *const indirectAcqusition in self.indirectAcquisitions) {
    [mutableIndirectAcquistionDictionaries addObject:[indirectAcqusition dictionary]];
  }

  return @{
    NYPLOPDSAcquisitionRelationKey: NYPLOPDSAcquisitionRelationString(self.relation),
    NYPLOPDSAcquisitionTypeKey: self.type,
    NYPLOPDSAcquisitionHrefURLKey: self.hrefURL.absoluteString,
    NYPLOPDSAcquisitionIndirectAcqusitionsKey: [mutableIndirectAcquistionDictionaries copy]
  };
}

@end
