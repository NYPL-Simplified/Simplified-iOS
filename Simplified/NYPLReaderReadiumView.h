@class NYPLBook;

@protocol NYPLReaderViewDelegate;

@interface NYPLReaderReadiumView : UIView <NYPLReaderView>

@property (nonatomic, weak) id<NYPLReaderViewDelegate> delegate;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame
                         book:(NYPLBook *)book
                     delegate:(id<NYPLReaderViewDelegate>)delegate;

@end
