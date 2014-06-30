@interface NYPLBook : NSObject

@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *title;

- (instancetype)initWithAuthorStrings:(NSArray *)authorStrings
                           identifier:(NSString *)identifier
                                title:(NSString *)title;

@end
