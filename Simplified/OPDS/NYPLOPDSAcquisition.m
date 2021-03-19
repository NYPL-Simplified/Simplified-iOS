#import "NYPLOPDSAcquisition.h"

#import "NYPLOPDSAcquisitionAvailability.h"
#import "NYPLOPDSIndirectAcquisition.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"

static NSString *const borrowRelationString = @"http://opds-spec.org/acquisition/borrow";
static NSString *const buyRelationString = @"http://opds-spec.org/acquisition/buy";
static NSString *const genericRelationString = @"http://opds-spec.org/acquisition";
static NSString *const openAccessRelationString = @"http://opds-spec.org/acquisition/open-access";
static NSString *const sampleRelationString = @"http://opds-spec.org/acquisition/sample";
static NSString *const subscribeRelationString = @"http://opds-spec.org/acquisition/subscribe";

static NSString *const availabilityKey = @"availability";
static NSString *const hrefURLKey = @"href";
static NSString *const indirectAcquisitionsKey = @"indirectAcqusitions";
static NSString *const relationKey = @"rel";
static NSString *const typeKey = @"type";

static NSString *const indirectAcquisitionName = @"indirectAcquisition";

static NSString *const relAttribute = @"rel";
static NSString *const typeAttribute = @"type";
static NSString *const hrefAttribute = @"href";

static NSUInteger const numberOfRelations = 6;

NYPLOPDSAcquisitionRelationSet const NYPLOPDSAcquisitionRelationSetAll = (1 << (numberOfRelations)) - 1;

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
NYPLOPDSAcquisitionRelationSetContainsRelation(NYPLOPDSAcquisitionRelationSet relationSet,
                                               NYPLOPDSAcquisitionRelation relation)
{
  return NYPLOPDSAcquisitionRelationSetWithRelation(relation) & relationSet;
}

BOOL
NYPLOPDSAcquisitionRelationWithString(NSString *const _Nonnull string,
                                      NYPLOPDSAcquisitionRelation *const _Nonnull relationPointer)
{
  static NSDictionary<NSString *, NSNumber *> *lazyStringToRelationObjectDict = nil;

  if (lazyStringToRelationObjectDict == nil) {
    lazyStringToRelationObjectDict = @{
      genericRelationString: @(NYPLOPDSAcquisitionRelationGeneric),
      openAccessRelationString: @(NYPLOPDSAcquisitionRelationOpenAccess),
      borrowRelationString: @(NYPLOPDSAcquisitionRelationBorrow),
      buyRelationString: @(NYPLOPDSAcquisitionRelationBuy),
      sampleRelationString: @(NYPLOPDSAcquisitionRelationSample),
      subscribeRelationString: @(NYPLOPDSAcquisitionRelationSubscribe)
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
      return genericRelationString;
    case NYPLOPDSAcquisitionRelationOpenAccess:
      return openAccessRelationString;
    case NYPLOPDSAcquisitionRelationBorrow:
      return borrowRelationString;
    case NYPLOPDSAcquisitionRelationBuy:
      return buyRelationString;
    case NYPLOPDSAcquisitionRelationSample:
      return sampleRelationString;
    case NYPLOPDSAcquisitionRelationSubscribe:
      return subscribeRelationString;
  }
}

@interface NYPLOPDSAcquisition ()

@property NYPLOPDSAcquisitionRelation relation;
@property (nonatomic, copy, nonnull) NSString *type;
@property (nonatomic, nonnull) NSURL *hrefURL;
@property (nonatomic, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;
@property (nonatomic, nonnull) id<NYPLOPDSAcquisitionAvailability> availability;

@end

@implementation NYPLOPDSAcquisition

+ (_Nonnull instancetype)
acquisitionWithRelation:(NYPLOPDSAcquisitionRelation const)relation
type:(NSString *const _Nonnull)type
hrefURL:(NSURL *const _Nonnull)hrefURL
indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcqusitions
availability:(id<NYPLOPDSAcquisitionAvailability> const _Nonnull)availability
{
  return [[self alloc] initWithRelation:relation
                                   type:type
                                hrefURL:hrefURL
                   indirectAcquisitions:indirectAcqusitions
                           availability:availability];
}

+ (_Nullable instancetype)acquisitionWithLinkXML:(NYPLXML *const _Nonnull)linkXML
{
  NSString *const relationString = [linkXML attributes][relAttribute];
  if (!relationString) {
    return nil;
  }

  NYPLOPDSAcquisitionRelation relation;
  if (!NYPLOPDSAcquisitionRelationWithString(relationString, &relation)) {
    return nil;
  }

  NSString *const type = [linkXML attributes][typeAttribute];
  if (!type) {
    return nil;
  }

  NSString *const hrefString = [linkXML attributes][hrefAttribute];
  if (!hrefString) {
    return nil;
  }

  NSURL *const hrefURL = [NSURL URLWithString:hrefString];
  if (!hrefURL) {
    return nil;
  }

  NSMutableArray<NYPLOPDSIndirectAcquisition *> *const mutableIndirectAcquisitions = [NSMutableArray array];
  for (NYPLXML *const indirectAcquisitionXML in [linkXML childrenWithName:indirectAcquisitionName]) {
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
                  indirectAcquisitions:[mutableIndirectAcquisitions copy]
                          availability:NYPLOPDSAcquisitionAvailabilityWithLinkXML(linkXML)];
}

- (_Nonnull instancetype)initWithRelation:(NYPLOPDSAcquisitionRelation const)relation
                                     type:(NSString *const _Nonnull)type
                                  hrefURL:(NSURL *const _Nonnull)hrefURL
                     indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *const _Nonnull)indirectAcqusitions
                             availability:(id<NYPLOPDSAcquisitionAvailability> const _Nonnull)availability
{
  self = [super init];

  self.relation = relation;
  self.type = type;
  self.hrefURL = hrefURL;
  self.indirectAcquisitions = indirectAcqusitions;
  self.availability = availability;

  return self;
}

+ (_Nullable instancetype)acquisitionWithDictionary:(NSDictionary *const _Nonnull)dictionary
{
  NSString *const relationString = dictionary[relationKey];
  if (![relationString isKindOfClass:[NSString class]]) {
    return nil;
  }

  NYPLOPDSAcquisitionRelation relation;
  if (!NYPLOPDSAcquisitionRelationWithString(relationString, &relation)) {
    return nil;
  }

  NSString *const type = dictionary[typeKey];
  if (![type isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSString *const hrefURLString = dictionary[hrefURLKey];
  if (![hrefURLString isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSURL *const hrefURL = [NSURL URLWithString:hrefURLString];
  if (!hrefURL) {
    return nil;
  }

  NSDictionary *const indirectAcquisitionDictionaries = dictionary[indirectAcquisitionsKey];
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

  NSDictionary *const availabilityDictionary = dictionary[availabilityKey];
  if (![availabilityDictionary isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  id<NYPLOPDSAcquisitionAvailability> const availability =
    NYPLOPDSAcquisitionAvailabilityWithDictionary(availabilityDictionary);

  if (!availability) {
    return nil;
  }

  return [NYPLOPDSAcquisition
          acquisitionWithRelation:relation
          type:type
          hrefURL:hrefURL
          indirectAcquisitions:[mutableIndirectAcquisitions copy]
          availability:availability];
}

- (NSDictionary *_Nonnull)dictionaryRepresentation
{
  NSMutableArray *const mutableIndirectAcquistionDictionaries =
    [NSMutableArray arrayWithCapacity:self.indirectAcquisitions.count];

  for (NYPLOPDSIndirectAcquisition *const indirectAcqusition in self.indirectAcquisitions) {
    [mutableIndirectAcquistionDictionaries addObject:[indirectAcqusition dictionaryRepresentation]];
  }

  return @{
    relationKey: NYPLOPDSAcquisitionRelationString(self.relation),
    typeKey: self.type,
    hrefURLKey: self.hrefURL.absoluteString,
    indirectAcquisitionsKey: [mutableIndirectAcquistionDictionaries copy],
    availabilityKey: NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation(self.availability)
  };
}

@end
