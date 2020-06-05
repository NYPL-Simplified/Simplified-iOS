@class NYPLReaderRendererOpaqueLocation;
@class NYPLReaderTOCViewController;
@class NYPLReadiumBookmark;

@protocol NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
  didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation;

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
        didSelectBookmark:(NYPLReadiumBookmark *)bookmark;

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
        didDeleteBookmark:(NYPLReadiumBookmark *)bookmark;

- (void)TOCViewController:(NYPLReaderTOCViewController *)controller
didRequestSyncBookmarksWithCompletion:
  (void(^)(BOOL success, NSArray<NYPLReadiumBookmark *> *bookmarks))completion;

@end

/// VC handling TOC and Bookmarks for Readium 1 reader.
@interface NYPLReaderTOCViewController : UIViewController

@property (nonatomic, weak) id<NYPLReaderTOCViewControllerDelegate> delegate;
@property (nonatomic) NSArray *tableOfContents;
@property (nonatomic) NSMutableArray<NYPLReadiumBookmark *> *bookmarks;
@property (nonatomic) NSString *bookTitle;
@property (nonatomic) NSString *currentChapter;


@end
