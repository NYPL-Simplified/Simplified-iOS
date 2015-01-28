#import "NYPLReaderRenderer.h"

@class NYPLBook;

@interface NYPLReaderRMSDKView : UIView <NYPLReaderRenderer>

@property (nonatomic, weak) id<NYPLReaderRendererDelegate> delegate;

- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame
                         book:(NYPLBook *)book
                     delegate:(id<NYPLReaderRendererDelegate>)delegate;

@end
