#import <Foundation/Foundation.h>

@class Account;
@class NYPLBook;
@class NYPLReaderBookmarkElement;

@protocol NYPLReadiumViewSyncManagerDelegate <NSObject>

@required

- (void)patronDecidedNavigation:(BOOL)toLatestPage
                    withNavDict:(NSDictionary *)dict;
- (void)updatePostLasReadStatus:(BOOL)status;

@optional

- (void)didCompleteBookmarkSync:(BOOL)success
                  withBookmarks:(NSArray<NYPLReaderBookmarkElement *> *)bookmarks;

@end

@interface NYPLReadiumViewSyncManager : NSObject

- (instancetype) initWithBook:(NYPLBook *)book
                      bookMap:(NSDictionary *)bookMap
                     delegate:(id)delegate;

- (void)syncAnnotationsForAccount:(Account *)account
                  withPackageDict:(NSDictionary *)dict;

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray *bookmarks))completion;


@end
