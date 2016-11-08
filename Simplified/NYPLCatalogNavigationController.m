#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"

@implementation NYPLCatalogNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLCatalogFeedViewController *const viewController =
    [[NYPLCatalogFeedViewController alloc]
     initWithURL:[NYPLConfiguration mainFeedURL]];
  
  viewController.title = NSLocalizedString(@"Catalog", nil);
  
  self = [super initWithRootViewController:viewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"lib-icon"];
  
  // The top-level view controller uses the same image used for the tab bar in place of the usual
  // title text.

  viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"lib-icon"] style:(UIBarButtonItemStylePlain)
                                                     
                                                     target:self
                                                     action:@selector(switchLibrary)];
  viewController.navigationItem.leftBarButtonItem.enabled = YES;
  
  
  return self;
}
-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NSString *library = [[NYPLSettings sharedSettings] currentLibrary];
  
  NSString *libraryName = @"New York Public Library";
  if ([library isEqualToString:@"0"])
  {
    libraryName = @"New York Public Library";
  }
  else if ([library isEqualToString:@"1"])
  {
    libraryName = @"Brooklyn Public Library";
  }
  else if ([library isEqualToString:@"2"])
  {
    libraryName = @"The Magic Library";
  }
  
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = libraryName;
  
  
}


- (void) switchLibrary
{
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick Your Library" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

  [alert addAction:[UIAlertAction actionWithTitle:@"New York Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"0"];
    
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];
    [[NYPLSettings sharedSettings] setCustomMainFeedURL:nil];

    
    [[NYPLBookRegistry sharedRegistry] justLoad];

    
    [self reloadSelected];

    
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"Brooklyn Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"1"];
   
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];
    [[NYPLSettings sharedSettings] setCustomMainFeedURL:nil];

    [[NYPLBookRegistry sharedRegistry] justLoad];



    [self reloadSelected];
    
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"The Magic Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    

    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"2"];
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];

    [[NYPLSettings sharedSettings] setCustomMainFeedURL:[NSURL URLWithString:@"http://oacontent.librarysimplified.org/"]];
    
    [[NYPLBookRegistry sharedRegistry] justLoad];

    //read local directory ???
    


    [self reloadSelected];
    
    
    
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil]];

  [[NYPLRootTabBarController sharedController]
   safelyPresentViewController:alert
   animated:YES
   completion:nil];
}


- (void) reloadSelected {
  if ([[self.visibleViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] && [self.visibleViewController respondsToSelector:@selector(load)]) {
    NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;
    viewController.URL = [NYPLConfiguration mainFeedURL]; // It may have changed
    [viewController load];
    
    NSString *library = [[NYPLSettings sharedSettings] currentLibrary];

    NSString *libraryName = @"New York Public Library";
    if ([library isEqualToString:@"0"])
    {
      libraryName = @"New York Public Library";
    }
    else if ([library isEqualToString:@"1"])
    {
      libraryName = @"Brooklyn Public Library";
    }
    else if ([library isEqualToString:@"2"])
    {
      libraryName = @"The Magic Library";
    }
    viewController.navigationItem.title = libraryName;

    
    
  }
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }
}

@end
