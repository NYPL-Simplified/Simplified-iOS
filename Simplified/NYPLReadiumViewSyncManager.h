#import <Foundation/Foundation.h>

@class Account;
@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReadiumBookmark;

typedef NS_ENUM(NSInteger, NYPLReadPositionSyncStatus) {
  NYPLReadPositionSyncStatusIdle,
  NYPLReadPositionSyncStatusBusy
};

@protocol NYPLReadiumViewSyncManagerDelegate <NSObject>

@required
- (void)patronDecidedNavigation:(BOOL)toLatestPage
                    withNavDict:(NSDictionary *)dict;

- (void)uploadFinishedForBookmark:(NYPLReadiumBookmark *)bookmark
                           inBook:(NSString *)bookID;
@end

@interface NYPLReadiumViewSyncManager : NSObject

- (instancetype)initWithBookID:(NSString *)bookID
                annotationsURL:(NSURL *)URL
                       bookMap:(NSDictionary *)map
                      delegate:(id)delegate;

- (void)syncAllAnnotationsWithPackage:(NSDictionary *)packageDict;
- (void)postLastReadPosition:(NSString *)location;

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray<NYPLReadiumBookmark *> *bookmarks))completion;

- (void)addBookmark:(NYPLReadiumBookmark *)bookmark
            withCFI:(NSString *)location
            forBook:(NSString *)bookID;

@end
