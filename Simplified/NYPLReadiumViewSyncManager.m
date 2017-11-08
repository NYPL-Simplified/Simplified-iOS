#import "NYPLReadiumViewSyncManager.h"

#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLJSON.h"
#import "NYPLReachability.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"
#import "SimplyE-Swift.h"

@class RDPackage;

@interface NYPLReadiumViewSyncManager ()

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NSDictionary *map;
@property (nonatomic, weak) id<NYPLReadiumViewSyncManagerDelegate> delegate;

@end


@implementation NYPLReadiumViewSyncManager

- (instancetype) initWithBook:(NYPLBook *)book
                      bookMap:(NSDictionary *)bookMap
                     delegate:(id)delegate
{
  self = [super init];
  if (self) {
    self.book = book;
    self.map = bookMap;
    self.delegate = delegate;
  }
  return self;
}

- (void)syncAnnotationsForAccount:(Account *)account
                  withPackageDict:(NSDictionary *)packageDict
{
  if (account.syncPermissionGranted) {

    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    dictionary[@"package"] = packageDict;
    dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
    NYPLBookLocation *const location = [[NYPLBookRegistry sharedRegistry]
                                        locationForIdentifier:self.book.identifier];

    [self syncLastReadingPosition:dictionary andLocation:location andBook:self.book];

    [self syncBookmarks];
  }
}

- (void)syncLastReadingPosition:(NSMutableDictionary *const)dictionary
                    andLocation:(NYPLBookLocation *const)location
                        andBook:(NYPLBook *const)book
{
  [NYPLAnnotations syncLastRead:book completionHandler:^(NSDictionary * _Nullable responseObject) {

    if (!responseObject) {
      NYPLLOG(@"Sync Error: No reponse object received from NYPLAnnotations.");
      return;
    }

    NSString* serverLocationString;
    NSString* currentLocationString;
    NSString* timestampString;
    NSString* deviceIDString;
    UIAlertController *alertController;

    NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:[responseObject[@"serverCFI"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    deviceIDString = responseObject[@"device"];
    timestampString = responseObject[@"time"];
    serverLocationString = responseObject[@"serverCFI"];
    currentLocationString = location.locationString;
    NYPLLOG_F(@"serverLocationString %@",serverLocationString);
    NYPLLOG_F(@"currentLocationString %@",currentLocationString);
    NSDictionary *spineItemDetails = self.map[responseJSON[@"idref"]];

    //GODO also seems like it's getting a message from it's own position, which it should not be doing
    //should be checking device ID and not showing the alert if it's from itself.

    NSString * message=[NSString stringWithFormat:@"Would you like to go to the latest page read?\n\nChapter:\n\"%@\"",spineItemDetails[@"tocElementTitle"]];

    alertController = [UIAlertController alertControllerWithTitle:@"Sync Reading Position"
                                                          message:message
                                                   preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:
     [UIAlertAction actionWithTitle:NSLocalizedString(@"NO", nil)
                              style:UIAlertActionStyleCancel
                            handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                              if ([self.delegate respondsToSelector:@selector(patronDecidedNavigation:withNavDict:)]) {
                                [self.delegate patronDecidedNavigation:NO withNavDict:nil];
                              }
                            }]];

    [alertController addAction:
     [UIAlertAction actionWithTitle:NSLocalizedString(@"YES", nil)
                              style:UIAlertActionStyleDefault
                            handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {

                              [self shouldPostLastRead:YES];

                              NSDictionary *const locationDictionary =
                              NYPLJSONObjectFromData([serverLocationString dataUsingEncoding:NSUTF8StringEncoding]);

                              NSString *contentCFI = locationDictionary[@"contentCFI"];
                              if (!contentCFI) {
                                contentCFI = @"";
                              }
                              dictionary[@"openPageRequest"] =
                              @{@"idref": locationDictionary[@"idref"], @"elementCfi": contentCFI};

                              if ([self.delegate respondsToSelector:@selector(patronDecidedNavigation:withNavDict:)]) {
                                [self.delegate patronDecidedNavigation:YES withNavDict:dictionary];
                              }
                            }]];

    // Pass through without presenting the Alert Controller if:
    // 1 - The most recent page on the server comes from the same device
    // 2 - The server and the client have the same page marked
    // 3 - There is no recent page saved on the server
    if ((currentLocationString && [deviceIDString isEqualToString:[NYPLAccount sharedAccount].deviceID]) ||
      [currentLocationString isEqualToString:serverLocationString] ||
      !serverLocationString) {
      [self shouldPostLastRead:YES];
    } else {
      [[NYPLRootTabBarController sharedController] safelyPresentViewController:alertController animated:YES completion:nil];
    }
  }];
}

- (void)shouldPostLastRead:(BOOL)status
{
  if ([self.delegate respondsToSelector:@selector(updatePostLasReadStatus:)]) {
    [self.delegate updatePostLasReadStatus:status];
  }
}

- (void)syncBookmarks
{
  [self syncBookmarksWithCompletion:^(BOOL success, NSArray *bookmarks) {
    if ([self.delegate respondsToSelector:@selector(didCompleteBookmarkSync:withBookmarks:)]) {
      [self.delegate didCompleteBookmarkSync:success withBookmarks:bookmarks];
    }
  }];
}

//GODO need to audit this class since not sure what it's going or why a delegate is needed at all
- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray *bookmarks))completion
{
  [[NYPLReachability sharedReachability]
   reachabilityForURL:[NYPLConfiguration mainFeedURL]
   timeoutInternal:8.0
   handler:^(BOOL reachable) {

     if (reachable) {

       // 1.
       // post all local bookmarks if they have not been posted yet,
       // this can happen if device was storing local bookmarks first and SImplyE Sync was enabled afterwards.

       NSArray<NYPLReaderBookmarkElement *> *localBookmarks = [[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.book.identifier];
       for (NYPLReaderBookmarkElement *localBookmark in localBookmarks) {

         if (localBookmark.annotationId.length == 0 || localBookmark.annotationId == nil) {

           [NYPLAnnotations postBookmark:self.book cfi:localBookmark.location bookmark:localBookmark completionHandler:^(NYPLReaderBookmarkElement *bookmark) {

             [[NYPLBookRegistry sharedRegistry] replaceBookmark:localBookmark with:bookmark forIdentifier:self.book.identifier];

           }];
         }
       }

       //GODO does this need to be nested from completion block of previous postBookmark operations??

       [NYPLAnnotations getBookmarks:self.book completionHandler:^(NSArray *remoteBookmarks) {

         // 2.
         // delete local bookmarks if annotation id exists locally but not remote

         NSMutableArray *keepLocalBookmarks = [[NSMutableArray alloc] init];
         for (NYPLReaderBookmarkElement *bookmark in remoteBookmarks) {

           NSPredicate *predicate = [NSPredicate predicateWithFormat:@"annotationId == %@", bookmark.annotationId];
           [keepLocalBookmarks addObjectsFromArray:[localBookmarks filteredArrayUsingPredicate:predicate]];

         }
         NYPLLOG(keepLocalBookmarks);

         NSMutableArray *deleteLocalBookmarks = [[NSMutableArray alloc] init];
         for (NYPLReaderBookmarkElement *bookmark in localBookmarks) {
           if (![keepLocalBookmarks containsObject:bookmark]) {
             [deleteLocalBookmarks addObject:bookmark];
           }
         }
         NYPLLOG(deleteLocalBookmarks);

         for (NYPLReaderBookmarkElement *bookmark in deleteLocalBookmarks) {
           [[NYPLBookRegistry sharedRegistry] deleteBookmark:bookmark forIdentifier:self.book.identifier];
         }

         // 3.
         // get remote bookmarks and store locally if not already stored

         NSMutableArray *addLocalBookmarks = remoteBookmarks.mutableCopy;
         NSMutableArray *ignoreBookmarks = [[NSMutableArray alloc] init];

         for (NYPLReaderBookmarkElement *bookmark in remoteBookmarks) {
           NSPredicate *predicate = [NSPredicate predicateWithFormat:@"annotationId == %@", bookmark.annotationId];
           [ignoreBookmarks addObjectsFromArray:[localBookmarks filteredArrayUsingPredicate:predicate]];
         }

         for (NYPLReaderBookmarkElement *el in remoteBookmarks) {
           for (NYPLReaderBookmarkElement *el2 in ignoreBookmarks) {
             if ([el isEqual:el2]) {
               [addLocalBookmarks removeObject:el];
             }
           }
         }

         for (NYPLReaderBookmarkElement *bookmark in addLocalBookmarks) {
           [[NYPLBookRegistry sharedRegistry] addBookmark:bookmark forIdentifier:self.book.identifier];
         }

         completion(YES,[[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.book.identifier]);

       }];
     }
   }];
}

@end
