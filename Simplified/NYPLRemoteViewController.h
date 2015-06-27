// This class is designed to provide a simple way to implement view controllers that must retreive
// some sort of network-available data before they can do anything. The idea is that an instance of
// |NYPLRemoteViewController| can be told to load the data present at some URL. While the data is
// downloading, it will display a progress indicator. Once the data has been retreived, the handler
// function provided will be called. That handler then returns a new view controller that is
// presented by the instance of |NYPLRemoteViewController|.

@interface NYPLRemoteViewController : UIViewController

// Neither |URL| nor |handler| may be nil. |completionHandler| will be called if and only if the
// data was downloaded successfully. In the event it was not, an error will be presented to the user
// with a button to begin another attempt. Calling this method while a load is already in progress
// will cancel the previous attempt.
//
// NOTE: An instance of |NYPLRemoteViewController| will keep a strong reference to |handler|. If
// your handler will reference the instance of |NYPLRemoteViewController| to which it is provided,
// ensure that it references it weakly.
- (void)loadURL:(NSURL *)URL completionHandler:(UIViewController *(^)(NSData *data))handler;

// This will cancel the current download if one is in progress, then attempt to fetch new data from
// the URL previously provided. Any currently presented view controller will be dismissed until new
// data is available, after which the previously provided handler will once again be invoked.
- (void)reload;

@end
