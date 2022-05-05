@class NYPLProblemDocument;
@class NYPLBookDetailDownloadFailedView;

@interface NYPLBookDetailDownloadFailedView : UIView

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@property (nonatomic) BOOL showAudiobookError;

- (void)configureFailMessageWithProblemDocument:(NYPLProblemDocument *)problemDoc;

@end
