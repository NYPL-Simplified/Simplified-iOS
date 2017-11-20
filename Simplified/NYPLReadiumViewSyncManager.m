#import "NYPLReadiumViewSyncManager.h"

#import "NSDate+NYPLDateAdditions.h"
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
    
    //GODO working on this at the moment.
    [self syncBookmarksWithCompletion:^(BOOL success, NSArray<NYPLReaderBookmarkElement *> *bookmarks) {
      if ([self.delegate respondsToSelector:@selector(didCompleteBookmarkSync:withBookmarks:)]) {
        [self.delegate didCompleteBookmarkSync:success withBookmarks:bookmarks];
      }
    }];
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
    if ([self.delegate respondsToSelector:@selector(getCurrentSpineDetailsForKey:)]) {
      spineItemDetails = [self.delegate getCurrentSpineDetailsForKey:responseJSON[@"idref"]];
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
  if ([self.delegate respondsToSelector:@selector(shouldPostReadingPosition:)]) {
    [self.delegate shouldPostReadingPosition:status];
  }
}

// GODO Bookmarks being added do not need to be queued if the upload fails.
// They will be considered a "local" bookmark for the book and will re-attempt upload on next sync for that book.
- (void)addBookmark:(NYPLReaderBookmarkElement *)bookmark
            withCFI:(NSString *)location
            forBook:(NSString *)bookID
{
  Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
  if (currentAccount.syncPermissionGranted) {
    [NYPLAnnotations postBookmarkForBook:bookID toURL:nil cfi:location bookmark:bookmark
                       completionHandler:^(BOOL success) {
                         if (success) {
                           [self.delegate bookmarkUploadDidFinish:bookmark forBook:bookID savedOnServer:YES];
                           NYPLLOG_F(@"Bookmark at location: %@ successfully uploaded to server.", location);
                         } else {
                           [self.delegate bookmarkUploadDidFinish:bookmark forBook:bookID savedOnServer:NO];
                           NYPLLOG_F(@"Bookmark at location: %@ failed to upload to server.", location);
                         }
                       }];
  } else {
    [self.delegate bookmarkUploadDidFinish:bookmark forBook:bookID savedOnServer:NO];
    NYPLLOG(@"Bookmark saving locally. Sync is not enabled for account.");
  }
}

- (void)syncBookmarksWithCompletion:(void(^)(BOOL success, NSArray<NYPLReaderBookmarkElement *> *bookmarks))completion
{
  [[NYPLReachability sharedReachability]
   reachabilityForURL:[NYPLConfiguration mainFeedURL]
   timeoutInternal:8.0
   handler:^(BOOL reachable) {

     if (!reachable) {
       NYPLLOG(@"Error: host was not reachable for bookmark sync attempt.");
       completion(NO, nil);
       return;
     }

     NSArray<NYPLReaderBookmarkElement *> *localBookmarks = [[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.bookID];

     // 1.
     // Upload local bookmarks if they have not been posted yet.
     // This can happen if the device was already storing local bookmarks, and Sync was enabled later.
     // When all requests have completed, execute completion block and provide any bookmarks not uploaded

     [NYPLAnnotations postLocalBookmarksWithBookmarks:localBookmarks forBook:self.bookID completion:^(NSArray<NYPLReaderBookmarkElement *> * _Nonnull bookmarksNotUploaded) {

         // After upload attempt finishes for local bookmarks,
         // Attempt to pull list of bookmarks from the server.

         [NYPLAnnotations getBookmarksForBook:self.bookID atURL:self.annotationsURL completionHandler:^(NSArray<NYPLReaderBookmarkElement *> * _Nonnull serverBookmarks) {

           if (serverBookmarks.count == 0) {
             NYPLLOG(@"No bookmarks were returned. No need to continue syncing.");
             return;
           }

           // 2.
           // Filter out bookmarks that don't exist on the server.

           NSMutableArray<NYPLReaderBookmarkElement *> *localBookmarksToKeep = [[NSMutableArray alloc] init];
           NSMutableArray<NYPLReaderBookmarkElement *> *serverBookmarksToDelete = [[NSMutableArray alloc] init];

           for (NYPLReaderBookmarkElement *serverBookmark in serverBookmarks) {
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"annotationId == %@", serverBookmark.annotationId];
             NSArray *matchingBookmarks = [localBookmarks filteredArrayUsingPredicate:predicate];
             [localBookmarksToKeep addObjectsFromArray:matchingBookmarks];

             if (matchingBookmarks.count == 0 &&
                 [serverBookmark.device isEqualToString:[[NYPLAccount sharedAccount] deviceID]]) {
               [serverBookmarksToDelete addObject:serverBookmark];
             }
           }

           // Add back in the bookmarks that failed to upload.
           [localBookmarksToKeep addObjectsFromArray:bookmarksNotUploaded];
           NYPLLOG_F(@"\nLocal Bookmarks To Keep:\n\n%@", localBookmarksToKeep);

           NSMutableArray<NYPLReaderBookmarkElement *> *localBookmarksToDelete = [[NSMutableArray alloc] init];
           for (NYPLReaderBookmarkElement *localBookmark in localBookmarks) {
             if (![localBookmarksToKeep containsObject:localBookmark]) {
               [localBookmarksToDelete addObject:localBookmark];
             }
           }
           NYPLLOG_F(@"\nLocal Bookmarks To Delete:\n\n%@", localBookmarksToDelete);

           for (NYPLReaderBookmarkElement *bookmark in localBookmarksToDelete) {
             [[NYPLBookRegistry sharedRegistry] deleteBookmark:bookmark forIdentifier:self.bookID];
           }

           // 3.
           // Search for any bookmarks that need to be stored locally.
           // Filter out any bookmarks that should be deleted on the server.

           NSMutableArray<NYPLReaderBookmarkElement *> *newBookmarksToSave = serverBookmarks.mutableCopy;
           [newBookmarksToSave removeObjectsInArray:serverBookmarksToDelete];
           for (NYPLReaderBookmarkElement *serverMark in serverBookmarks) {
             for (NYPLReaderBookmarkElement *localMark in localBookmarksToKeep) {
               if ([serverMark isEqual:localMark]) {
                 [newBookmarksToSave removeObject:serverMark];
               }
             }
           }

           for (NYPLReaderBookmarkElement *bookmark in newBookmarksToSave) {
             [[NYPLBookRegistry sharedRegistry] addBookmark:bookmark forIdentifier:self.bookID];
           }

           NYPLLOG_F(@"\nServer Bookmarks To Delete:\n\n%@", serverBookmarksToDelete);
           
//           [NYPLAnnotations deleteBookmarks:serverBookmarksToDelete completion...]
           //GODO Send delete request

           completion(YES,[[NYPLBookRegistry sharedRegistry] bookmarksForIdentifier:self.bookID]);

         }];
     }];
   }];
}

@end
