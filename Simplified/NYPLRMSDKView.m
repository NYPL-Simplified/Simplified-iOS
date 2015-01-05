#import "NYPLRMSDKView.h"

@interface NYPLRMSDKView ()

@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) BOOL loaded;

@end

@implementation NYPLRMSDKView

- (instancetype)initWithFrame:(CGRect const)frame
                         book:(__attribute__((unused)) NYPLBook *const)book
                     delegate:(id<NYPLReaderRendererDelegate> const)delegate
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  self.delegate = delegate;
  
  // TODO: Intialize with |book|.
  
  return self;
}

#pragma mark NYPLReaderRenderer

- (void)openOpaqueLocation:(__attribute__((unused))
                            NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  // TODO: Check if |[opaqueLocation isKindOfClass:[SomeClass class]]|, else throw
  // |NSInvalidArgumentException|.
  
  // TODO: Open location.
}

- (NSArray *)TOCElements
{
  // TODO
  
  return nil;
}

@end
