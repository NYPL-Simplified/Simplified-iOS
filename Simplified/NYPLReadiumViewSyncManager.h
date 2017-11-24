#import <Foundation/Foundation.h>

@class Account;
@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReaderBookmarkElement;

@protocol NYPLReadiumViewSyncManagerDelegate <NSObject>

@required
// From UIALert, user made decision
// to stay or to leave current page
- (void)patronDecidedNavigation:(BOOL)toLatestPage
                    withNavDict:(NSDictionary *)dict;

- (void)shouldPostReadingPosition:(BOOL)status;

-(void)bookmarkUploadDidFinish:(NYPLReaderBookmarkElement *)bookmark
                       forBook:(NSString *)bookID
                 savedOnServer:(BOOL)success;

@optional
- (void)didCompleteBookmarkSync:(BOOL)success
                  withBookmarks:(NSArray<NYPLReaderBookmarkElement *> *)bookmarks;
@end

@interface NYPLReadiumViewSyncManager : NSObject

- (instancetype) initWithBookID:(NSString *)bookID
                 annotationsURL:(NSURL *)URL
                        bookMap:(NSDictionary *)map
                       delegate:(id)delegate;

- (void)syncAnnotationsWithPermissionForAccount:(Account *)account
                                withPackageDict:(NSDictionary *)packageDict;

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray<NYPLReaderBookmarkElement *> *bookmarks))completion;

- (void)addBookmark:(NYPLReaderBookmarkElement *)bookmark
            withCFI:(NSString *)location
            forBook:(NSString *)bookID;

@end
