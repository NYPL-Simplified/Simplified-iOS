//#import "NYPLBookState.h"
//
//static NSString *const Downloading = @"downloading";
//static NSString *const DownloadFailed = @"download-failed";
//static NSString *const DownloadNeeded = @"download-needed";
//static NSString *const DownloadSuccessful = @"download-successful";
//static NSString *const Unregistered = @"unregistered";
//static NSString *const Holding = @"holding";
//static NSString *const Used = @"used";
//static NSString *const Unsupported = @"unsupported";
//
//NYPLBookState NYPLBookStateFromString(NSString *const string)
//{
//  if([string isEqualToString:Downloading]) return NYPLBookStateDownloading;
//  if([string isEqualToString:DownloadFailed]) return NYPLBookStateDownloadFailed;
//  if([string isEqualToString:DownloadNeeded]) return NYPLBookStateDownloadNeeded;
//  if([string isEqualToString:DownloadSuccessful]) return NYPLBookStateDownloadSuccessful;
//  if([string isEqualToString:Unregistered]) return NYPLBookStateUnregistered;
//  if([string isEqualToString:Holding]) return NYPLBookStateHolding;
//  if([string isEqualToString:Used]) return NYPLBookStateUsed;
//  if([string isEqualToString:Unsupported]) return NYPLBookStateUnsupported;
//
//  @throw NSInvalidArgumentException;
//}
//
//NSString *NYPLBookStateToString(NYPLBookState state)
//{
//  switch(state) {
//    case NYPLBookStateDownloading:
//      return Downloading;
//    case NYPLBookStateDownloadFailed:
//      return DownloadFailed;
//    case NYPLBookStateDownloadNeeded:
//      return DownloadNeeded;
//    case NYPLBookStateDownloadSuccessful:
//      return DownloadSuccessful;
//    case NYPLBookStateUnregistered:
//      return Unregistered;
//    case NYPLBookStateHolding:
//      return Holding;
//    case NYPLBookStateUsed:
//      return Used;
//    case NYPLBookStateUnsupported:
//      return Unsupported;
//  }
//}
