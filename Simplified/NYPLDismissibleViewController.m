#import "NYPLDismissibleViewController.h"

@interface NYPLDismissibleViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation NYPLDismissibleViewController

#pragma mark UIViewController

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(didReceiveGesture:)];
  self.tapGestureRecognizer.cancelsTouchesInView = NO;
  self.tapGestureRecognizer.delegate = self;
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  
  [self.view.window addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark -

-(BOOL)gestureRecognizer:(__attribute__((unused)) UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(__attribute__((unused))
                                                    UIGestureRecognizer*)otherGestureRecognizer
{
  return YES;
}

- (void)didReceiveGesture:(UIGestureRecognizer *const)gestureRecognizer
{
  if(self.presentedViewController) return;
  
  if (![self.navigationController.view pointInside:[gestureRecognizer locationInView:self.navigationController.view] withEvent:nil]) {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
