@import Foundation;

@interface NYPLCatalogAcquisitions : NSObject

@property (nonatomic, readonly) NSURL *borrow; // nilable
@property (nonatomic, readonly) NSURL *buy; // nilable
@property (nonatomic, readonly) NSURL *generic; // nilable
@property (nonatomic, readonly) NSURL *openAccess; // nilable
@property (nonatomic, readonly) NSURL *sample; // nilable
@property (nonatomic, readonly) NSURL *subscribe; // nilable

// designated initializer
- (id)initWithBorrow:(NSURL *)borrow
                 buy:(NSURL *)buy
             generic:(NSURL *)generic
          openAccess:(NSURL *)openAccess
              sample:(NSURL *)sample
           subscribe:(NSURL *)subscribe;


@end
