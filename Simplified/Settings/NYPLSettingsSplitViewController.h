@protocol NYPLCurrentLibraryAccountProvider;

@interface NYPLSettingsSplitViewController : UISplitViewController

- (instancetype)initWithCurrentLibraryAccountProvider: (id<NYPLCurrentLibraryAccountProvider>)currentAccountProvider;

@end
