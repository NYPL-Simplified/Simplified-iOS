@protocol NYPLCurrentLibraryAccountProvider;

@interface NYPLSettingsSplitViewControllerOld : UISplitViewController

- (instancetype)initWithCurrentLibraryAccountProvider: (id<NYPLCurrentLibraryAccountProvider>)currentAccountProvider;

@end
