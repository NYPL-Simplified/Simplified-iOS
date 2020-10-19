#import "NYPLMyBooksDownloadInfo.h"

@interface NYPLMyBooksDownloadInfo ()

@property (nonatomic) CGFloat downloadProgress;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) NYPLMyBooksDownloadRightsManagement rightsManagement;

@end

@implementation NYPLMyBooksDownloadInfo

- (instancetype)initWithDownloadProgress:(CGFloat const)downloadProgress
                            downloadTask:(NSURLSessionDownloadTask *const)downloadTask
                        rightsManagement:(NYPLMyBooksDownloadRightsManagement const)rightsManagement
{
  self = [super init];
  if(!self) return nil;
  
  self.downloadProgress = downloadProgress;
  
  if(!downloadTask) @throw NSInvalidArgumentException;
  self.downloadTask = downloadTask;

  self.rightsManagement = rightsManagement;
  
  return self;
}

- (instancetype)withDownloadProgress:(CGFloat const)downloadProgress
{
  return [[[self class] alloc]
          initWithDownloadProgress:downloadProgress
          downloadTask:self.downloadTask
          rightsManagement:self.rightsManagement];
}

- (instancetype)withRightsManagement:(NYPLMyBooksDownloadRightsManagement const)rightsManagement
{
  return [[[self class] alloc]
          initWithDownloadProgress:self.downloadProgress
          downloadTask:self.downloadTask
          rightsManagement:rightsManagement];
}

- (NSString *)rightsManagementString
{
  switch (self.rightsManagement) {
    case NYPLMyBooksDownloadRightsManagementUnknown:
      return @"Unknown";
    case NYPLMyBooksDownloadRightsManagementNone:
      return @"None";
    case NYPLMyBooksDownloadRightsManagementAdobe:
      return @"Adobe";
    case NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON:
      return @"SimplifiedBearerTokenJSON";
    case NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON:
      return @"OverdriveManifestJSON";
    default:
      return [NSString stringWithFormat:@"Unexpected value: %ld",
              (long)self.rightsManagement];
  }
}

@end
