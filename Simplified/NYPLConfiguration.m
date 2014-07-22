#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (void)initialize
{
  [[UIButton appearance] setTintColor:[self mainColor]];
  
  [[UINavigationBar appearance]
   setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Bold"
                                                                 size:18.0]}];
  
  [[UINavigationBar appearance] setTintColor:[self mainColor]];
  
  [[UIBarButtonItem appearance]
   setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium"
                                                                 size:18.0]}
   forState:UIControlStateNormal];
  
  [[UITabBarItem appearance]
   setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Medium"
                                                                 size:12.0]}
   forState:UIControlStateNormal];
  
  [[UITabBar appearance] setTintColor:[self mainColor]];
}

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
  // return [NSURL URLWithString:@"http://10.128.36.26:5000/lanes/eng"];
}

+ (UIColor *)mainColor
{
  return [UIColor colorWithRed:240/255.0 green:115/255.0 blue:31/255.0 alpha:1.0];
}

@end
