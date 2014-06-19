@import Foundation;

@interface NYPLCatalogAcquisition : NSObject

@property (nonatomic, readonly) NSURL *borrow; // nilable
@property (nonatomic, readonly) NSURL *generic; // nilable
@property (nonatomic, readonly) NSURL *openAccess; // nilable
@property (nonatomic, readonly) NSURL *sample; // nilable

// designated initializer
- (id)initWithBorrow:(NSURL *)borrow
             generic:(NSURL *)generic
          openAccess:(NSURL *)openAccess
              sample:(NSURL *)sample;


@end
