#import "NYPLOPDSCategory.h"

@interface NYPLOPDSCategory ()

@property (nonatomic, copy, nonnull) NSString *term;
@property (nonatomic, copy, nullable) NSString *label;
@property (nonatomic, nullable) NSURL *scheme;

@end

@implementation NYPLOPDSCategory

- (nonnull instancetype)initWithTerm:(nonnull NSString *const)term
                               label:(nullable NSString *const)label
                              scheme:(nullable NSURL *const)scheme
{
  if(!term) {
    @throw NSInvalidArgumentException;
  }
  
  self = [super init];
  
  self.term = term;
  self.label = label;
  self.scheme = scheme;
  
  return self;
}

+ (nonnull NYPLOPDSCategory *)categoryWithTerm:(nonnull NSString *const)term
                                         label:(nullable NSString *const)label
                                        scheme:(nullable NSURL *const)scheme
{
  return [[NYPLOPDSCategory alloc] initWithTerm:term label:label scheme:scheme];
}

@end
