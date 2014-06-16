#import "NYPLCatalogAcquisitions.h"

@interface NYPLCatalogAcquisitions ()

@property (nonatomic) NSURL *borrow;
@property (nonatomic) NSURL *buy;
@property (nonatomic) NSURL *generic;
@property (nonatomic) NSURL *openAccess;
@property (nonatomic) NSURL *sample;
@property (nonatomic) NSURL *subscribe;

@end

@implementation NYPLCatalogAcquisitions

- (id)initWithBorrow:(NSURL *const)borrow
                 buy:(NSURL *const)buy
             generic:(NSURL *const)generic
          openAccess:(NSURL *const)openAccess
              sample:(NSURL *const)sample
           subscribe:(NSURL *const)subscribe
{
  self = [super init];
  if(!self) return nil;
  
  self.borrow = borrow;
  self.buy = buy;
  self.generic = generic;
  self.openAccess = openAccess;
  self.sample = sample;
  self.subscribe = subscribe;
  
  return self;
}

@end
