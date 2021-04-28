@import Foundation;

@interface NYPLOPDSCategory : NSObject

@property (nonatomic, readonly, nonnull) NSString *term;
@property (nonatomic, readonly, nullable) NSString *label;
@property (nonatomic, readonly, nullable) NSURL *scheme;

+ (nonnull instancetype)new NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithTerm:(nonnull NSString *)term
                               label:(nullable NSString *)label
                              scheme:(nullable NSURL *)scheme NS_DESIGNATED_INITIALIZER;

+ (nonnull NYPLOPDSCategory *)categoryWithTerm:(nonnull NSString *)term
                                         label:(nullable NSString *)label
                                        scheme:(nullable NSURL *)scheme;

@end
