/// This class is designed to provide a simple way to implement view controllers that must retrieve
/// some sort of network-available data before they can do anything. The idea is that an instance of
/// |NYPLRemoteViewController| can be told to load the data present at some URL. While the data is
/// downloading, it will display a progress indicator. Once the data has been retrieved, the handler
/// function provided will be called. That handler then returns a new view controller that is
/// added as a child vc by the instance of |NYPLRemoteViewController|.
///
/// The current left and right bar buttons of the presented view controller, as well as the current
/// title, will be displayed. Changes to said properties later on will not be shown, so be sure they
/// are all set before the handler returns. (Changes to the items already /within/ the left and right
/// sets of items will be correctly displayed, however.)
///
/// For more information, see Apple's documentation on view controller containers.
@interface NYPLRemoteViewController : UIViewController

/// After changing this, you must call |load| to see the effect.
/// For this class to work in a meaningful way, @p URL must be not-nil.
@property (atomic, readonly) NSURL *URL;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 This is the designated initializer.
 @param URL The URL where to fetch the data at.
 @param handler Must not be nil. It is strongly retained. The @p data parameter
 will never be @p nil as this handler is only called if the download was
 successful. This may return nil to indicate that there's something wrong
 with the downloaded data. If a view controller is returned, it will be added
 as a child view controller.
 */
- (instancetype)initWithURL:(NSURL *)URL
                    handler:(UIViewController *(^)(NYPLRemoteViewController *remoteViewController,
                                                   NSData *data,
                                                   NSURLResponse *response))handler;

/// This may be called more than once to reload the data accessible at the previously provided URL.
/// This message must be sent on the main thread.
/// If the @p URL property is nil, this results in a no-op. 
- (void)load;

/// Updates the @p URL property with the input @p url and calls @p load.
/// @param url The new URL to load.
- (void)loadWithURL:(NSURL*)url;

/**
 Shows a view with an error message and a reload button.
 @param message The message to display. If nil, a default "Check your internet
 connection" error message will be displayed.
 */
- (void)showReloadViewWithMessage:(NSString*)message;

@end
