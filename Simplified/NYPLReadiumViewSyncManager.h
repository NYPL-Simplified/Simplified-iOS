#import <Foundation/Foundation.h>

@class Account;
@class NYPLBook;
@class NYPLReaderBookmarkElement;

@protocol NYPLReadiumViewSyncManagerDelegate <NSObject>

@required
// From UIALert, user made decision
// to stay or to leave current page
- (void)patronDecidedNavigation:(BOOL)toLatestPage
                    withNavDict:(NSDictionary *)dict;

- (void)shouldPostReadingPosition:(BOOL)status;

- (NSDictionary *)getCurrentSpineDetailsFromJSON:(NSDictionary *)responseJSON;

@optional
- (void)didCompleteBookmarkSync:(BOOL)success
                  withBookmarks:(NSArray<NYPLReaderBookmarkElement *> *)bookmarks;
@end

@interface NYPLReadiumViewSyncManager : NSObject

- (instancetype) initWithBookID:(NSString *)bookID
                 annotationsURL:(NSURL *)URL
                       delegate:(id)delegate;

- (void)syncAnnotationsWithPermissionForAccount:(Account *)account
                                withPackageDict:(NSDictionary *)packageDict;

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray *bookmarks))completion;


@end
