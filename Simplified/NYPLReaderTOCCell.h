@interface NYPLReaderTOCCell : UITableViewCell

@property (nonatomic) NSUInteger nestingLevel;
@property (nonatomic) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
