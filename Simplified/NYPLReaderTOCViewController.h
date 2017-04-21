@class NYPLReaderRendererOpaqueLocation;
@class NYPLReaderTOCViewController;
@class RDNavigationElement;

@protocol NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation;

@end

@interface NYPLReaderTOCViewController : UIViewController

@property (nonatomic, weak) id<NYPLReaderTOCViewControllerDelegate> delegate;
@property (nonatomic) NSArray *tableOfContents;
@property (nonatomic) NSArray *bookmarks;


@end
