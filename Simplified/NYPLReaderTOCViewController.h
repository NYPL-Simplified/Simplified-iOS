@class NYPLReaderRendererOpaqueLocation;
@class NYPLReaderTOCViewController;
@class RDNavigationElement;
@class NYPLReaderBookmarkElement;

@protocol NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation;

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
didSelectBookmark:(NYPLReaderBookmarkElement *)bookmark;

@end

@interface NYPLReaderTOCViewController : UIViewController

@property (nonatomic, weak) id<NYPLReaderTOCViewControllerDelegate> delegate;
@property (nonatomic) NSArray *tableOfContents;
@property (nonatomic) NSMutableArray *bookmarks;
@property (nonatomic) NSString *bookTitle;


@end
