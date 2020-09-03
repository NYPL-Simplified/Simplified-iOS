// When a download starts, its rights management status will be unknown. It will only become known
// after the response from the server has been received and we've gotten back a MIME type.
typedef NS_ENUM(NSInteger, NYPLMyBooksDownloadRightsManagement) {
  NYPLMyBooksDownloadRightsManagementUnknown,
  NYPLMyBooksDownloadRightsManagementNone,
  NYPLMyBooksDownloadRightsManagementAdobe,
  NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON,
  NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON
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

- (instancetype)withRightsManagement:(NYPLMyBooksDownloadRightsManagement)rightsManagement;

- (NSString *)rightsManagementString;

@end
