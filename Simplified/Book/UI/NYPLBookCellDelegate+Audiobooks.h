//
//  NYPLBookCellDelegate+Audiobooks.h
//  Simplified
//
//  Created by Ettore Pasquini on 10/19/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

#if FEATURE_AUDIOBOOKS

@class NYPLBook;

@import NYPLAudiobookToolkit;

#import "NYPLBookCellDelegate.h"

@interface NYPLBookCellDelegate (Audiobooks) <RefreshDelegate>

- (void)openAudiobook:(NYPLBook *)book successCompletion:(void(^)(void))successCompletion;

@end

#endif
