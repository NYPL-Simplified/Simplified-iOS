typedef NS_ENUM(NSInteger, NYPLMyBooksDownloadRightsManagement) {
  NYPLMyBooksDownloadRightsManagementNone,
  NYPLMyBooksDownloadRightsManagementAdobe
};

@interface NYPLMyBooksDownloadInfo : NSObject

@property (nonatomic, readonly) CGFloat downloadProgress;
@property (nonatomic, readonly) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, readonly) NYPLMyBooksDownloadRightsManagement rightsManagement;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithDownloadProgress:(CGFloat)downloadProgress
                            downloadTask:(NSURLSessionDownloadTask *)downloadTask
                        rightsManagement:(NYPLMyBooksDownloadRightsManagement)rightsManagement;

- (instancetype)withDownloadProgress:(CGFloat)downloadProgress;

@end
