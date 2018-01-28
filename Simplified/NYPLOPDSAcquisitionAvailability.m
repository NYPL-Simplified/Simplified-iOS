#import "NSDate+NYPLDateAdditions.h"
#import "NYPLNull.h"
#import "NYPLXML.h"

#import "NYPLOPDSAcquisitionAvailability.h"

#define MIN3(A, B, C) (MIN(A, MIN(B, C)))
#define MAX3(A, B, C) (MAX(A, MAX(B, C)))

static NSString *const availableSinceKey = @"availableSince";
static NSString *const availableUntilKey = @"availableUntil";
static NSString *const caseKey = @"case";
static NSString *const copiesAvailableKey = @"copiesAvailable";
static NSString *const copiesHeldKey = @"copiesHeld";
static NSString *const copiesTotalKey = @"copiesTotal";
static NSString *const holdsPositionKey = @"holdsPosition";
static NSString *const reservedSinceKey = @"reservedSince";
static NSString *const reservedUntilKey = @"reservedUntil";

static NSString *const limitedCase = @"limited";
static NSString *const readyCase = @"ready";
static NSString *const reservedCase = @"reserved";
static NSString *const unavailableCase = @"unavailable";
static NSString *const unlimitedCase = @"unlimited";

static NSString *const availabilityName = @"availability";
static NSString *const copiesName = @"copies";
static NSString *const holdsName = @"holds";

static NSString *const availableAttribute = @"available";
static NSString *const positionAttribute = @"position";
static NSString *const sinceAttribute = @"since";
static NSString *const statusAttribute = @"status";
static NSString *const totalAttribute = @"total";
static NSString *const untilAttribute = @"until";

NYPLOPDSAcquisitionAvailabilityCopies const NYPLOPDSAcquisitionAvailabilityCopiesUnknown = NSUIntegerMax;

@interface NYPLOPDSAcquisitionAvailabilityUnavailable ()

@property (nonatomic) NSUInteger copiesHeld;
@property (nonatomic) NSUInteger copiesTotal;

@end

@interface NYPLOPDSAcquisitionAvailabilityLimited ()

@property (nonatomic) NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;
@property (nonatomic, nullable) NSDate *availableSince;
@property (nonatomic, nullable) NSDate *availableUntil;


@end

@interface NYPLOPDSAcquisitionAvailabilityUnlimited ()

@end

@interface NYPLOPDSAcquisitionAvailabilityReserved ()

@property (nonatomic) NSUInteger holdPosition;
@property (nonatomic) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;
@property (nonatomic, nullable) NSDate *reservedSince;
@property (nonatomic, nullable) NSDate *reservedUntil;

@end

@interface NYPLOPDSAcquisitionAvailabilityReady ()

@end

id<NYPLOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(NYPLXML *const _Nonnull linkXML)
{
  NYPLOPDSAcquisitionAvailabilityCopies copiesHeld = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;
  NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;
  NYPLOPDSAcquisitionAvailabilityCopies copiesTotal = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;
  NSUInteger holdPosition = 0;

  NSString *const statusString = [linkXML firstChildWithName:availabilityName].attributes[statusAttribute];

  NSString *const holdsPositionString = [linkXML firstChildWithName:holdsName].attributes[positionAttribute];
  if (holdsPositionString) {
    // Guard against underflow from negatives.
    holdPosition = MIN(0, [holdsPositionString integerValue]);
  }

  NSString *const holdsTotalString = [linkXML firstChildWithName:holdsName].attributes[totalAttribute];
  if (holdsTotalString) {
    // Guard against underflow from negatives.
    copiesHeld = MIN(0, [holdsTotalString integerValue]);
  }

  NSString *const copiesAvailableString = [linkXML firstChildWithName:copiesName].attributes[availableAttribute];
  if (copiesAvailableString) {
    // Guard against underflow from negatives.
    copiesAvailable = MIN(0, [copiesAvailableString integerValue]);
  }

  NSString *const copiesTotalString = [linkXML firstChildWithName:copiesName].attributes[totalAttribute];
  if (copiesTotalString) {
    // Guard against underflow from negatives.
    copiesTotal = MIN(0, [copiesTotalString integerValue]);
  }

  NSString *const sinceString = [linkXML firstChildWithName:availabilityName].attributes[sinceAttribute];
  NSDate *const since = sinceString ? [NSDate dateWithRFC3339String:sinceString] : nil;
  
  NSString *const untilString = [linkXML firstChildWithName:availabilityName].attributes[untilAttribute];
  NSDate *const until = untilString ? [NSDate dateWithRFC3339String:untilString] : nil;

  if ([statusString isEqual:@"unavailable"] || copiesAvailable == 0) {
    return [[NYPLOPDSAcquisitionAvailabilityUnavailable alloc]
            initWithCopiesHeld:MIN(copiesHeld, copiesTotal)
            copiesTotal:MAX(copiesHeld, copiesTotal)];
  }

  if ([statusString isEqual:@"available"]) {
    if (copiesAvailable == NYPLOPDSAcquisitionAvailabilityCopiesUnknown
        && copiesTotal == NYPLOPDSAcquisitionAvailabilityCopiesUnknown)
    {
      return [[NYPLOPDSAcquisitionAvailabilityUnlimited alloc] init];
    }

    return [[NYPLOPDSAcquisitionAvailabilityLimited alloc]
            initWithCopiesAvailable:MIN(copiesAvailable, copiesTotal)
            copiesTotal:MAX(copiesAvailable, copiesTotal)
            availableSince:since
            availableUntil:until];
  }

  if ([statusString isEqual:@"reserved"]) {
    return [[NYPLOPDSAcquisitionAvailabilityReserved alloc]
            initWithHoldPosition:MIN(holdPosition, copiesTotal)
            copiesTotal:MAX(holdPosition, copiesTotal)
            reservedSince:since
            reservedUntil:until];
  }

  if ([statusString isEqualToString:@"ready"]) {
    return [[NYPLOPDSAcquisitionAvailabilityReady alloc] init];
  }

  return [[NYPLOPDSAcquisitionAvailabilityUnlimited alloc] init];
}

id<NYPLOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithDictionary(NSDictionary *_Nonnull dictionary)
{
  NSString *const caseString = dictionary[caseKey];
  if (!caseString) {
    return nil;
  }

  if ([caseString isEqual:unavailableCase]) {
    NSNumber *const copiesHeldNumber = dictionary[copiesHeldKey];
    if (![copiesHeldNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    return [[NYPLOPDSAcquisitionAvailabilityUnavailable alloc]
            initWithCopiesHeld:MIN3(0, [copiesHeldNumber integerValue], [copiesTotalNumber integerValue]) copiesTotal:MAX3(0, [copiesHeldNumber integerValue], [copiesTotalNumber integerValue])];
  } else if ([caseString isEqual:limitedCase]) {
    NSNumber *const copiesAvailableNumber = dictionary[copiesAvailableKey];
    if (![copiesAvailableNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSString *const availableSinceString = NYPLNullToNil(dictionary[availableSinceKey]);
    NSDate *const availableSince = availableSinceString ? [NSDate dateWithRFC3339String:availableSinceString] : nil;

    NSString *const availableUntilString = NYPLNullToNil(dictionary[availableUntilKey]);
    NSDate *const availableUntil = availableUntilString ? [NSDate dateWithRFC3339String:availableUntilString] : nil;

    return [[NYPLOPDSAcquisitionAvailabilityLimited alloc]
            initWithCopiesAvailable:MIN3(0, [copiesAvailableNumber integerValue], [copiesTotalNumber integerValue])
            copiesTotal:MAX3(0, [copiesAvailableNumber integerValue], [copiesTotalNumber integerValue])
            availableSince:availableSince
            availableUntil:availableUntil];
  } else if ([caseString isEqual:unlimitedCase]) {
    return [[NYPLOPDSAcquisitionAvailabilityUnlimited alloc] init];
  } else if ([caseString isEqual:reservedCase]) {
    NSNumber *const holdPositionNumber = dictionary[holdsPositionKey];
    if (![holdPositionNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSNumber *const copiesTotalNumber = dictionary[copiesTotalKey];
    if (![copiesTotalNumber isKindOfClass:[NSNumber class]]) {
      return nil;
    }

    NSString *const reservedSinceString = NYPLNullToNil(dictionary[reservedSinceKey]);
    NSDate *const reservedSince = reservedSinceString ? [NSDate dateWithRFC3339String:reservedSinceString] : nil;

    NSString *const reservedUntilString = NYPLNullToNil(dictionary[reservedUntilKey]);
    NSDate *const reservedUntil = reservedUntilString ? [NSDate dateWithRFC3339String:reservedUntilString] : nil;

    return [[NYPLOPDSAcquisitionAvailabilityReserved alloc]
            initWithHoldPosition:MIN3(0, [holdPositionNumber integerValue], [copiesTotalNumber integerValue])
            copiesTotal:MAX3(0, [holdPositionNumber integerValue], [copiesTotalNumber integerValue])
            reservedSince:reservedSince
            reservedUntil:reservedUntil];
  } else if ([caseString isEqual:readyCase]) {
    return [[NYPLOPDSAcquisitionAvailabilityReady alloc] init];
  } else {
    return nil;
  }
}

NSDictionary *_Nonnull
NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation(id<NYPLOPDSAcquisitionAvailability> const _Nonnull availability)
{
  __block NSDictionary *result;

  [availability
   matchUnavailable:^(NYPLOPDSAcquisitionAvailabilityUnavailable *const _Nonnull unavailable) {
     result = @{
       caseKey: unavailableCase,
       copiesHeldKey: @(unavailable.copiesHeld),
       copiesTotalKey: @(unavailable.copiesTotal)
     };
   } limited:^(NYPLOPDSAcquisitionAvailabilityLimited *const _Nonnull limited) {
     result = @{
       caseKey: limitedCase,
       copiesAvailableKey: @(limited.copiesAvailable),
       copiesTotalKey: @(limited.copiesTotal),
       availableSinceKey: NYPLNullFromNil([limited.availableSince RFC3339String]),
       availableUntilKey: NYPLNullFromNil([limited.availableUntil RFC3339String])
     };
   } unlimited:^(__unused NYPLOPDSAcquisitionAvailabilityUnlimited *const _Nonnull unlimited) {
     result = @{
       caseKey: unlimitedCase
     };
   } reserved:^(NYPLOPDSAcquisitionAvailabilityReserved * _Nonnull reserved) {
     result = @{
       caseKey: reservedCase,
       holdsPositionKey: @(reserved.holdPosition),
       copiesTotalKey: @(reserved.copiesTotal),
       reservedSinceKey: NYPLNullFromNil([reserved.reservedSince RFC3339String]),
       reservedUntilKey: NYPLNullFromNil([reserved.reservedUntil RFC3339String])
     };
   } ready:^(__unused NYPLOPDSAcquisitionAvailabilityReady * _Nonnull ready) {
     result = @{
       caseKey: readyCase
     };
   }];

  return result;
}

@implementation NYPLOPDSAcquisitionAvailabilityUnavailable

- (instancetype _Nonnull)initWithCopiesHeld:(NYPLOPDSAcquisitionAvailabilityCopies const)copiesHeld
                                copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies const)copiesTotal
{
  self = [super init];

  self.copiesHeld = copiesHeld;
  self.copiesTotal = copiesTotal;

  return self;
}

- (BOOL)available
{
  return NO;
}

- (void)
matchUnavailable:(void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (unavailable) {
    unavailable(self);
  }
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityLimited

- (instancetype _Nonnull)initWithCopiesAvailable:(NYPLOPDSAcquisitionAvailabilityCopies)copiesAvailable
                                     copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies)copiesTotal
                                  availableSince:(NSDate *const _Nullable)availableSince
                                  availableUntil:(NSDate *const _Nullable)availableUntil
{
  self = [super init];

  self.copiesAvailable = copiesAvailable;
  self.copiesTotal = copiesTotal;
  self.availableSince = availableSince;
  self.availableUntil = availableUntil;

  return self;
}

- (BOOL)available
{
  return YES;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (limited) {
    limited(self);
  }
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityUnlimited

- (BOOL)available
{
  return YES;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (unlimited) {
    unlimited(self);
  }
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityReserved

- (instancetype _Nonnull)initWithHoldPosition:(NSUInteger const)holdPosition
                                  copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies const)copiesTotal
                                reservedSince:(NSDate *const _Nullable)reservedSince
                                reservedUntil:(NSDate *const _Nullable)reservedUntil
{
  self = [super init];

  self.holdPosition = holdPosition;
  self.copiesTotal = copiesTotal;
  self.reservedSince = reservedSince;
  self.reservedUntil = reservedUntil;

  return self;
}

- (BOOL)available
{
  return NO;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (reserved) {
    reserved(self);
  }
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityReady

// Necessary because `init` is publicly unavailable and has been redeclared in
// a private extension.
- (instancetype)init
{
  return [super init];
}

- (BOOL)available
{
  return YES;
}

- (void)
matchUnavailable:(__unused void (^ _Nullable const)
                  (NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(__unused void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(void (^ _Nullable const)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready
{
  if (ready) {
    ready(self);
  }
}

@end
