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
  
  if(!self.downloadTask) @throw NSInvalidArgumentException;
  self.downloadTask = downloadTask;

  self.rightsManagement = rightsManagement;
  
  return self;
}

- (instancetype)withDownloadProgress:(CGFloat const)downloadProgress
{
  NYPLMyBooksDownloadInfo *const updatedInfo = [self copy];
  updatedInfo.downloadProgress = downloadProgress;
  
  return updatedInfo;
}

@end
