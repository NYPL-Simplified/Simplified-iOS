#import "NYPLCatalogNavigationController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLSettingsNavigationController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;
@property (nonatomic) NYPLMyBooksNavigationController *myBooksNavigationController;
@property (nonatomic) NYPLHoldsNavigationController *holdsNavigationController;
@property (nonatomic) NYPLSettingsNavigationController *settingsNavigationController;

@end

@implementation NYPLRootTabBarController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.catalogNavigationController = [[NYPLCatalogNavigationController alloc] init];
  self.myBooksNavigationController = [[NYPLMyBooksNavigationController alloc] init];
  self.holdsNavigationController = [[NYPLHoldsNavigationController alloc] init];
  self.settingsNavigationController = [[NYPLSettingsNavigationController alloc] init];
  
  self.viewControllers = @[self.catalogNavigationController,
                           self.myBooksNavigationController,
                           self.holdsNavigationController,
                           self.settingsNavigationController];
  
  return self;
}

@end
