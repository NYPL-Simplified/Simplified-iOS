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

@property (nonatomic) NSString *bookID;
@property (nonatomic) NSURL *annotationsURL;
@property (nonatomic, weak) id<NYPLReadiumViewSyncManagerDelegate> delegate;

@end


@implementation NYPLReadiumViewSyncManager

- (instancetype) initWithBookID:(NSString *)bookID
                 annotationsURL:(NSURL *)URL
                       delegate:(id)delegate
{
  self = [super init];
  if (self) {
    self.bookID = bookID;
    self.annotationsURL = URL;
    self.delegate = delegate;
  }
  return self;
}

- (void)syncAnnotationsWithPermissionForAccount:(Account *)account
                                withPackageDict:(NSDictionary *)packageDict
{
  if (account.syncPermissionGranted) {

    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    dictionary[@"package"] = packageDict;
    dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
    NYPLBookLocation *const location = [[NYPLBookRegistry sharedRegistry]
                                        locationForIdentifier:self.bookID];
    
    [self syncReadingPositionForBook:self.bookID
                          atLocation:location
                               toURL:self.annotationsURL
                         withPackage:dictionary];
    [self syncBookmarks];
  }
}

- (void)syncReadingPositionForBook:(NSString *)bookID
                        atLocation:(NYPLBookLocation *)location
                             toURL:(NSURL *)URL
                       withPackage:(NSMutableDictionary *)dictionary
{
  [NYPLAnnotations syncReadingPositionOfBook:bookID toURL:URL
              completionHandler:^(NSDictionary * _Nullable responseObject) {

    if (!responseObject) {
      NYPLLOG(@"No Server Annotation for this book exists.");
      [self shouldPostLastRead:YES];
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

    NSDictionary *spineItemDetails;
    NSString *elementTitle;
    if ([self.delegate respondsToSelector:@selector(getCurrentSpineDetailsFromJSON:)]) {
      spineItemDetails = [self.delegate getCurrentSpineDetailsFromJSON:responseJSON];
      elementTitle = spineItemDetails[@"tocElementTitle"];
    }
    if (!elementTitle) {
      elementTitle = @"";
    }
                
    NSString * message=[NSString stringWithFormat:@"Would you like to go to the latest page read?\n\nChapter:\n\"%@\"",elementTitle];

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

       NSArray<NYPLReaderBookmarkElement *> *localBookmarks = [[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.bookID];
       for (NYPLReaderBookmarkElement *localBookmark in localBookmarks) {

         if (localBookmark.annotationId.length == 0 || localBookmark.annotationId == nil) {
           [NYPLAnnotations postBookmarkForBook:self.bookID
                                          toURL:nil
                                            cfi:localBookmark.location
                                       bookmark:localBookmark
                              completionHandler:^(NYPLReaderBookmarkElement * _Nullable bookmark) {
                                [[NYPLBookRegistry sharedRegistry] replaceBookmark:localBookmark
                                                                              with:bookmark
                                                                     forIdentifier:self.bookID];
                              }];
         }
       }

       //GODO does this need to be nested from completion block of previous postBookmark operations??
       
       [NYPLAnnotations getBookmarksForBook:self.bookID atURL:self.annotationsURL completionHandler:^(NSArray<NYPLReaderBookmarkElement *> * _Nonnull remoteBookmarks) {  //GODO make sure this _Nonnull works
         
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
           [[NYPLBookRegistry sharedRegistry] deleteBookmark:bookmark forIdentifier:self.bookID];
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
           [[NYPLBookRegistry sharedRegistry] addBookmark:bookmark forIdentifier:self.bookID];
         }

         completion(YES,[[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.bookID]);

       }];
     }
   }];
}

@end
