#import <Foundation/Foundation.h>

@class Account;
@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReaderBookmark;

@protocol NYPLReadiumViewSyncManagerDelegate <NSObject>

@required
- (void)patronDecidedNavigation:(BOOL)toLatestPage
                    withNavDict:(NSDictionary *)dict;

- (void)shouldPostReadingPosition:(BOOL)status;

- (void)uploadFinishedForBookmark:(NYPLReaderBookmark *)bookmark
                           inBook:(NSString *)bookID;

@optional
- (void)didCompleteBookmarkSync:(BOOL)success
                  withBookmarks:(NSArray<NYPLReaderBookmark *> *)bookmarks;
@end

@interface NYPLReadiumViewSyncManager : NSObject

- (instancetype)initWithBookID:(NSString *)bookID
                annotationsURL:(NSURL *)URL
                       bookMap:(NSDictionary *)map
                      delegate:(id)delegate;

- (void)syncAnnotationsWithPermissionForAccount:(Account *)account
                                withPackageDict:(NSDictionary *)packageDict;

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray<NYPLReaderBookmark *> *bookmarks))completion;

- (void)addBookmark:(NYPLReaderBookmark *)bookmark
            withCFI:(NSString *)location
            forBook:(NSString *)bookID;

@end
