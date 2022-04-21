//
//  NYPLBookCellDelegate+Audiobooks.m
//  Simplified
//
//  Created by Ettore Pasquini on 10/19/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

#if FEATURE_AUDIOBOOKS

#if FEATURE_OVERDRIVE_AUTH
@import OverdriveProcessor;
#endif

#import "SimplyE-Swift.h"

#import "NYPLBookCellDelegate+Audiobooks.h"
#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLJSON.h"
#import "NSString+NYPLStringAdditions.h"

@implementation NYPLBookCellDelegate (Audiobooks)

#pragma mark - Audiobook Methods

- (void)openAudiobook:(NYPLBook *)book {
  // If an audiobook download is in progress, we should use the existing AudiobookManager.
  DefaultAudiobookManager *audiobookManager = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] audiobookManagerForBookID:book.identifier];
  if (audiobookManager) {
    [self presentAudiobook:book withAudiobookManager:audiobookManager];
    return;
  }
  
  NSURL *url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] fileURLForBookIndentifier:book.identifier];
  
  [AudiobookManifestAdapter transformManifestToDictionaryFor:book
                                                     fileURL:url
                                                  completion:^(NSDictionary<NSString *,id> * _Nullable json,
                                                               id<DRMDecryptor> _Nullable decryptor,
                                                               enum AudiobookManifestError error) {
    switch (error) {
      case AudiobookManifestErrorCorrupted:
        [self presentCorruptedItemErrorWithLog:@{
          @"book": book.loggableDictionary ?: @"N/A",
          @"fileURL": url ?: @"N/A"
        }];
        return;
      case AudiobookManifestErrorUnsupported:
        [self presentUnsupportedItemError];
        return;
      case AudiobookManifestErrorNone:
        break;
    }
    
    [self openAudiobook:book withJSON:json decryptor:decryptor];
  }];
}

- (void)presentAudiobook:(NYPLBook *)book withAudiobookManager:(DefaultAudiobookManager *)audiobookManager {
  [NYPLMainThreadRun asyncIfNeeded:^{
    AudiobookPlayerViewController *audiobookVC = [self createPlayerVCForAudiobook:audiobookManager.audiobook
                                                                         withBook:book
                                                      configuringAudiobookManager:audiobookManager];

    // present audiobook player on screen
    [[NYPLRootTabBarController sharedController] pushViewController:audiobookVC animated:YES];
    
    NYPLBookLocation *const bookLocation =
    [[NYPLBookRegistry sharedRegistry] locationForIdentifier:book.identifier];

    // move player to saved position
    if (bookLocation) {
      NSData *const data = [bookLocation.locationString dataUsingEncoding:NSUTF8StringEncoding];
      ChapterLocation *const chapterLocation = [ChapterLocation fromData:data];
      NYPLLOG_F(@"Returning to Audiobook Location: %@", chapterLocation);
      [audiobookManager.audiobook.player movePlayheadToLocation:chapterLocation];
    }
    
    // poll audiobook player so that we can save the reading position
    [self scheduleTimerForAudiobook:book manager:audiobookManager viewController:audiobookVC];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scheduleAudiobookProgressSavingTimer)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
  }];
}

- (void)openAudiobook:(NYPLBook *)book withJSON:(NSDictionary *)json decryptor:(id<DRMDecryptor>)audiobookDrmDecryptor {
  [AudioBookVendorsHelper updateVendorKeyWithBook:json completion:^(NSError * _Nullable error) {
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      id<Audiobook> const audiobook = [AudiobookFactory audiobook:json decryptor:audiobookDrmDecryptor];

      if (!audiobook) {
        if (error) {
          [self presentDRMKeyError:error];
        } else {
          [self presentUnsupportedItemError];
        }
        return;
      }

      AudiobookMetadata *const metadata = [[AudiobookMetadata alloc]
                                           initWithTitle:book.title
                                           authors:@[book.authors]];
      DefaultAudiobookManager *const manager = [[DefaultAudiobookManager alloc]
                                                initWithMetadata:metadata
                                                audiobook:audiobook];

      [self presentAudiobook:book withAudiobookManager:manager];
    }];
  }];
}

- (AudiobookPlayerViewController *)createPlayerVCForAudiobook:(id<Audiobook>)audiobook
                                                     withBook:(NYPLBook *)book
                                  configuringAudiobookManager:(id<AudiobookManager>)manager
{
  manager.refreshDelegate = self;

  AudiobookPlayerViewController *const audiobookVC = [[AudiobookPlayerViewController alloc]
                                                      initWithAudiobookManager:manager];

  [self registerCallbackForLogHandler];

  [[NYPLBookRegistry sharedRegistry] coverImageForBook:book handler:^(UIImage *image) {
    if (image) {
      [audiobookVC.coverView setImage:image];
    }
  }];

  audiobookVC.hidesBottomBarWhenPushed = YES;
  audiobookVC.view.tintColor = [NYPLConfiguration mainColor];

  __weak AudiobookPlayerViewController *weakAudiobookVC = audiobookVC;
  [manager setPlaybackCompletionHandler:^{
    NSSet<NSString *> *types = [[NSSet alloc] initWithObjects:ContentTypeFindaway, ContentTypeOpenAccessAudiobook, ContentTypeFeedbooksAudiobook, nil];
    NSArray<NYPLOPDSAcquisitionPath *> *paths = [NYPLOPDSAcquisitionPath
                                                 supportedAcquisitionPathsForAllowedTypes:types
                                                 allowedRelations:(NYPLOPDSAcquisitionRelationSetBorrow |
                                                                   NYPLOPDSAcquisitionRelationSetGeneric)
                                                 acquisitions:book.acquisitions];
    if (paths.count > 0) {
      UIAlertController *alert = [NYPLReturnPromptHelper audiobookPromptWithCompletion:^(BOOL returnWasChosen) {
        if (returnWasChosen) {
          [weakAudiobookVC.navigationController popViewControllerAnimated:YES];
          [self didSelectReturnForBook:book];
        }
        [NYPLAppStoreReviewPrompt presentIfAvailable];
      }];
      [[NYPLRootTabBarController sharedController] presentViewController:alert animated:YES completion:nil];
    } else {
      NYPLLOG(@"Skipped Return Prompt with no valid acquisition path.");
      [NYPLAppStoreReviewPrompt presentIfAvailable];
    }
  }];

  return audiobookVC;
}

- (void)registerCallbackForLogHandler
{
  [DefaultAudiobookManager setLogHandler:^(enum LogLevel level, NSString * _Nonnull msg, NSError * _Nullable error) {
    // unfortunately since any kind of error (possibly including low level
    // errors) can end up here, we have no way of providing a more relevant
    // summary (e.g. extracting it from the `error`)
    NSString *logLevel = (level == LogLevelInfo ? @"info" :
                          (level == LogLevelWarn ? @"warning" : @"error"));
    NSString *summary = [NSString stringWithFormat:@"NYPLAudiobookToolkit %@", logLevel];
    NSDictionary *metadata = @{
      @"context": msg,
      @"book": [self.book loggableDictionary] ?: @"N/A",
    };

    if (error) {
      [NYPLErrorLogger logError:error
                        summary:summary
                       metadata:metadata];
    } else if (level > LogLevelDebug) {
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAudiobookExternalError
                                summary:summary
                               metadata:metadata];
    }
  }];
}

// Non-thread safe: currently this is always called on the main thread.
// Even more stricly, since NTPLBookCellDelegate is a singleton (!?), this
// method should be called only when the previous audiobookViewController is
// no longer used.
- (void)scheduleTimerForAudiobook:(NYPLBook *)book
                          manager:(DefaultAudiobookManager *)manager
                   viewController:(AudiobookPlayerViewController *)audiobookVC
{
  self.book = book;
  self.manager = manager;

  __weak UIViewController *const weakAudiobookVC = audiobookVC;
  [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *_Nonnull timer) {
    if (weakAudiobookVC == nil) {
      [timer invalidate];
      NYPLLOG(@"Invalidating audiobook polling timer and resetting BookCellDelegate state");
      self.book = nil;
      self.manager = nil;
      return;
    }

    NSString *const string = [[NSString alloc]
                              initWithData:manager.audiobook.player.currentChapterLocation.toData
                              encoding:NSUTF8StringEncoding];
    [[NYPLBookRegistry sharedRegistry]
     setLocation:[[NYPLBookLocation alloc] initWithLocationString:string renderer:@"NYPLAudiobookToolkit"]
     forIdentifier:book.identifier];
  }];
}

- (void)scheduleAudiobookProgressSavingTimer {
  [self scheduleProgressSavingTimerForAudiobookManager:self.manager];
}

- (void)presentDRMKeyError:(NSError *) error
{
  NSString *title = NSLocalizedString(@"DRM Error", nil);
  NSString *message = error.localizedDescription;
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}

- (void)presentCorruptedItemErrorWithLog:(NSDictionary *)loggingMetadata
{
  NSString *title = NSLocalizedString(@"Corrupted Audiobook", nil);
  NSString *message = NSLocalizedString(@"The audiobook you are trying to open appears to be corrupted. Try downloading it again.", nil);
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];

  [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAudiobookCorrupted
                            summary:@"Audiobooks: corrupted audiobook"
                           metadata:loggingMetadata];
}

#pragma mark - Audiobook Manager Refresh Delegate

- (void)audiobookManagerDidRequestRefresh
{
#if FEATURE_OVERDRIVE_AUTH
  // while `audiobookManagerDidRequestRefresh` is guaranteed to be called
  // always on the main thread, this lock prevents us from starting the book
  // download a second time before reaching a completion for the first.
  if (![self.refreshAudiobookLock tryLock]) {
    return;
  }

  if ([self.book.distributor isEqualToString:OverdriveAPI.distributorKey]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateODAudiobookManifest:)
                                                 name:NSNotification.NYPLMyBooksDownloadCenterDidChange
                                               object:nil];
  } else {
    [self.refreshAudiobookLock unlock];
  }
#endif//FEATURE_OVERDRIVE_AUTH

  [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadNeeded forIdentifier:self.book.identifier];
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:self.book];
}

#if FEATURE_OVERDRIVE_AUTH
- (void)updateODAudiobookManifest:(NSNotification *)notif
{
  NSString *bookID = notif.userInfo[NYPLNotificationKeys.bookIDKey];

  // if MyBooks changed for any reason but a book update (in which case we
  // would have a nonnull book ID), then it must mean it's either a reset or
  // anyways something that does not concern us because not related to a
  // specific book.
  // Note that if for whatever reason AudioBookVC is deallocated before this
  // callback is called, `self.book` will be nil or potentially *different*.
  if (bookID == nil || bookID.isEmptyNoWhitespace) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
    return;
  }

  NYPLBookState bookState = [[NYPLBookRegistry sharedRegistry]
                             stateForIdentifier:bookID];
  if (bookState == NYPLBookStateDownloadFailed) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
    return;
  }

  if (bookState == NYPLBookStateDownloadSuccessful || bookState == NYPLBookStateUsed) {
    // sanity check before casting. Note that self.manager could be nil.
    if (![(NSObject*)self.manager.audiobook isKindOfClass:[OverdriveAudiobook class]]) {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [self.refreshAudiobookLock unlock];
      return;
    }

    // odAudiobook definitely nonnull
    OverdriveAudiobook *odAudiobook = (OverdriveAudiobook * __nonnull)self.manager.audiobook;

    NSURL *const bookURL = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                            fileURLForBookIndentifier:bookID];
    NSData *const bookData = [NSData dataWithContentsOfURL:bookURL];
    if (bookData == nil) {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [self.refreshAudiobookLock unlock];
      [self presentCorruptedItemErrorWithLog:@{
        @"book/bookID": self.book.loggableDictionary ?: bookID,
        @"fileURL": bookURL ?: @"N/A"
      }];
      return;
    }

    // update Overdrive audiobook object with id
    id const json = NYPLJSONObjectFromData(bookData);
    NSMutableDictionary *dict = [(NSMutableDictionary *)json mutableCopy];
    dict[@"id"] = bookID;
    [odAudiobook updateManifestWithJSON:dict];

    [self.manager updateAudiobookWith:odAudiobook.spine];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
  }
}
#endif//FEATURE_OVERDRIVE_AUTH

@end

#endif//FEATURE_AUDIOBOOKS
