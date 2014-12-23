@class NYPLBook;

@protocol NYPLReaderViewDelegate;

@interface NYPLReaderReadiumView : NSObject <NYPLReaderView>

@property (nonatomic, weak) id<NYPLReaderViewDelegate> delegate;

- (instancetype)initWithBook:(NYPLBook *)book
                    delegate:(id<NYPLReaderViewDelegate>)delegate;

@end
