#import "NYPLXML.h"

#import "NYPLOPDSAcquisitionAvailability.h"

NYPLOPDSAcquisitionAvailabilityCopies const NYPLOPDSAcquisitionAvailabilityCopiesUnknown = NSUIntegerMax;

@interface NYPLOPDSAcquisitionAvailabilityUnavailable ()

@property (nonatomic) NSUInteger copiesHeld;
@property (nonatomic) NSUInteger copiesTotal;

- (instancetype)init;

@end

@interface NYPLOPDSAcquisitionAvailabilityLimited ()

@property (nonatomic) NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

- (instancetype)init;

@end

@interface NYPLOPDSAcquisitionAvailabilityUnlimited ()

- (instancetype)init;

@end

id<NYPLOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(NYPLXML *const _Nonnull linkXML)
{
  NYPLOPDSAcquisitionAvailabilityCopies copiesHeld = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;
  NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;
  NYPLOPDSAcquisitionAvailabilityCopies copiesTotal = NYPLOPDSAcquisitionAvailabilityCopiesUnknown;

  NSString *const statusString = [linkXML firstChildWithName:@"availability"].attributes[@"status"];

  NSString *const holdsString = [linkXML firstChildWithName:@"holds"].attributes[@"total"];
  if (holdsString) {
    // Guard against underflow from negatives.
    copiesHeld = MIN(0, [holdsString integerValue]);
  }

  NSString *const availableString = [linkXML firstChildWithName:@"copies"].attributes[@"available"];
  if (availableString) {
    // Guard against underflow from negatives.
    copiesAvailable = MIN(0, [availableString integerValue]);
  }

  NSString *const totalString = [linkXML firstChildWithName:@"copies"].attributes[@"total"];
  if (totalString) {
    // Guard against underflow from negatives.
    copiesTotal = MIN(0, [totalString integerValue]);
  }

  if ([statusString isEqual:@"unavailable"] || copiesAvailable == 0) {
    NYPLOPDSAcquisitionAvailabilityUnavailable *const unavailable =
      [[NYPLOPDSAcquisitionAvailabilityUnavailable alloc] init];

    unavailable.copiesHeld = MIN(copiesHeld, copiesTotal);
    unavailable.copiesTotal = MAX(copiesHeld, copiesTotal);

    return unavailable;
  }

  if (copiesAvailable == NYPLOPDSAcquisitionAvailabilityCopiesUnknown
      && copiesTotal == NYPLOPDSAcquisitionAvailabilityCopiesUnknown)
  {
    return [[NYPLOPDSAcquisitionAvailabilityUnlimited alloc] init];
  }

  NYPLOPDSAcquisitionAvailabilityLimited *const limited = [[NYPLOPDSAcquisitionAvailabilityLimited alloc] init];

  limited.copiesAvailable = MIN(copiesAvailable, copiesTotal);
  limited.copiesTotal = MAX(copiesAvailable, copiesTotal);

  return limited;
}

@implementation NYPLOPDSAcquisitionAvailabilityUnavailable

// Necessary because `init` is publicly unavailable and has been redeclared in
// a private extension.
- (instancetype)init
{
  return [super init];
}

- (BOOL)available
{
  return NO;
}

- (void)matchUnavailable:(void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull))unavailable
limited:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull))limited
unlimited:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull))unlimited
{
  unavailable(self);
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityLimited

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
matchUnavailable:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull))unavailable
limited:(void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull))limited
unlimited:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull))unlimited
{
  limited(self);
}

@end

@implementation NYPLOPDSAcquisitionAvailabilityUnlimited

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
matchUnavailable:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull))unavailable
limited:(__unused void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull))limited
unlimited:(void (^ const _Nullable)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull))unlimited
{
  unlimited(self);
}

@end

