#import "NYPLOPDSAcquisition.h"

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

NYPLOPDSAcquisitionRelation
NYPLOPDSAcquisitionRelationWithString(NSString *const _Nonnull string, BOOL *const _Nonnull success)
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
    *success = NO;
    return (NYPLOPDSAcquisitionRelation) NSIntegerMax;
  }

  *success = YES;

  return relationObject.integerValue;
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
