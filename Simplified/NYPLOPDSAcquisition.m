#import "NYPLOPDSAcquisition.h"

#import "NYPLOPDSIndirectAcquisition.h"
#import "NYPLXML.h"

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
@property (copy, nonnull) NSString *type;
@property (nonnull) NSURL *hrefURL;
@property (nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

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

@end
