//
//  NYPLLocationCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLLocationCardController.h"
#import "CJAMacros.h"
#import "NYPLAnimatingButton.h"
#import "NYPLCardApplicationModel.h"
@import CoreLocation;

static NSString *s_checkmarkImageName = @"Check";

typedef enum {
  NYPLLocationStateUnknown,
  NYPLLocationStateInsideNY,
  NYPLLocationStateOutsideNY,
  NYPLLocationStateCouldNotDetermine
} NYPLLocationState;

@interface NYPLLocationCardController () <CLLocationManagerDelegate> {
  CGPathRef *_paths;
  size_t _pathCount;
}
@property (nonatomic, assign) NYPLLocationState state;
@property (nonatomic, assign) BOOL isDeterminingLocation;
@property (nonatomic, assign) BOOL requestingContinuousUpdates;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) IBOutlet UILabel *successLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@end

@implementation NYPLLocationCardController
@synthesize currentApplication;

- (void) loadNYStatePolygonFromJSON:(NSDictionary *)json
{
  // This is pretty specific to one particular json file, so let's make a few assertions in case a future developer tries to load another file or something
  NSAssert([json[@"type"] isEqualToString:@"Feature"], @"GeoJSON file must be a feature");
  NSAssert([json[@"geometry"][@"type"] isEqualToString:@"MultiPolygon"], @"GeoJSON file must contain a single MultiPolygon");
  _pathCount = [(NSArray *) json[@"geometry"][@"coordinates"] count];
  _paths = (CGPathRef *) malloc(_pathCount * sizeof(CGPathRef *));
  
  for (uint i=0; i<_pathCount; ++i) {
    CGMutablePathRef path = CGPathCreateMutable();
    _paths[i] = path;
    NSArray *polygon = json[@"geometry"][@"coordinates"][i][0];
    
    for (uint j=0; j<polygon.count; ++j) {
      CGPoint p = CGPointMake([polygon[j][0] floatValue], [polygon[j][1] floatValue]);
      if (j==0)
        CGPathMoveToPoint(path, NULL, p.x, p.y);
      else
        CGPathAddLineToPoint(path, NULL, p.x, p.y);
    }
    
    CGPathCloseSubpath(path);
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"nystate" withExtension:@"geojson"];
  NSData *data = [NSData dataWithContentsOfURL:url];
  NSDictionary *geoJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  [self loadNYStatePolygonFromJSON:geoJSON];
}

- (void) dealloc
{
  for (uint i=0; i<_pathCount; i++)
    CGPathRelease(_paths[i]);
  free(_paths);
  _pathCount = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.continueButton.enabled = NO;
  
  if (!currentApplication.isInNYState) {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
      self.state = NYPLLocationStateCouldNotDetermine;
    }
    
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
      self.state = NYPLLocationStateUnknown;
    }
  }
  
  self.title = NSLocalizedString(@"Location", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
    
  // Get the user's location
  if (nil == self.locationManager) {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
  }
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(NSFoundationVersionNumber_iOS_8_0)) {
    [self.locationManager requestWhenInUseAuthorization];
  } else {
    self.requestingContinuousUpdates = YES;
    [self.locationManager startUpdatingLocation];
  }
}

- (void)setIsDeterminingLocation:(BOOL)isDeterminingLocation
{
  if (self.isDeterminingLocation != isDeterminingLocation) {
    _isDeterminingLocation = isDeterminingLocation;
    
    if (isDeterminingLocation) {
      if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(NSFoundationVersionNumber_iOS_8_0)) {
        [self.locationManager requestLocation];
      } else {
        self.requestingContinuousUpdates = YES;
        [self.locationManager startUpdatingLocation];
      }
    } else {
      if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(NSFoundationVersionNumber_iOS_8_0)) {
        self.requestingContinuousUpdates = NO;
        [self.locationManager stopUpdatingLocation];
      }
    }
  }
}

- (void)couldNotDetermineLocation
{
  __weak NYPLCardApplicationViewController *weakSelf = self;
  self.viewDidAppearCallback = ^() {
    weakSelf.viewDidAppearCallback = nil;
    [weakSelf performSegueWithIdentifier:@"photo" sender:nil];
  };
  [self performSegueWithIdentifier:@"error" sender:nil];
}

- (void)locationOutsideNY
{
  __weak NYPLCardApplicationViewController *weakSelf = self;
  self.viewDidAppearCallback = ^() {
    weakSelf.viewDidAppearCallback = nil;
    [weakSelf performSegueWithIdentifier:@"photo" sender:nil];
  };
  [self performSegueWithIdentifier:@"error" sender:nil];
}

- (void)locationInsideNY
{
  self.state = NYPLLocationStateInsideNY;
}

- (IBAction)continueToPhoto:(__attribute__((unused)) id)sender
{
  [self performSegueWithIdentifier:@"photo" sender:nil];
}

-(IBAction)checkLocation:(__attribute__((unused)) id)sender
{
  if (!self.isDeterminingLocation)
    self.isDeterminingLocation = YES;
}

- (void)setState:(NYPLLocationState)state
{
  _state = state;
  self.currentApplication.isInNYState = (state == NYPLLocationStateInsideNY);
  if (state == NYPLLocationStateUnknown) {
    self.checkButton.alpha = 1.0;
    self.successLabel.text = @"";
    self.continueButton.enabled = NO;
    
  } else if (state == NYPLLocationStateOutsideNY) {
    self.checkButton.alpha = 1.0;
    self.successLabel.text = NSLocalizedString(@"You're outside New York State. You can still apply for a card, but you won't be able to borrow books until it arrives.", nil);
    [self.continueButton setEnabled:YES animated:YES];
    
  } else if (state == NYPLLocationStateInsideNY) {
    [UIView transitionWithView:self.successLabel
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.successLabel.text = NSLocalizedString(@"Hello New York! You're good to go", nil);
                    } completion:nil];
    [UIView transitionWithView:self.checkButton
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^() {
                      self.checkButton.alpha = 0.0;
                    } completion:nil];
    [UIView transitionWithView:self.imageView
                      duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                      self.imageView.image = [UIImage imageNamed:s_checkmarkImageName];
                    } completion:^(BOOL finished) {
                      if (finished) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                          [self.continueButton setEnabled:YES animated:YES];
                        });
                      }
                    }];
    
  } else if (state == NYPLLocationStateCouldNotDetermine) {
    self.checkButton.alpha = 1.0;
    self.successLabel.text = NSLocalizedString(@"Could not determine your location. You can still apply for a card, but you won't be able to borrow books until it arrives.", nil);
    [self.continueButton setEnabled:YES animated:YES];
    
  }
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark Location

- (void) locationManager:(__attribute__((unused)) CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
    [self setState:NYPLLocationStateCouldNotDetermine];
  }
}

- (void) locationManager:(__attribute__((unused)) CLLocationManager *)manager didFailWithError:(__attribute__((unused)) NSError *)error
{
  if (error.code != 0)
    [self couldNotDetermineLocation];
}

- (void) locationManager:(__attribute__((unused)) CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
  if (self.requestingContinuousUpdates) {
    self.requestingContinuousUpdates = NO;
    [self.locationManager stopUpdatingLocation];
  }
  
  // Should only be one location--check if it's in NYState
  CLLocation *location = locations.firstObject;
  CGPoint mapPointAsCGP = CGPointMake(location.coordinate.longitude, location.coordinate.latitude);
  BOOL isInNYState = NO;
  for (uint i=0; i<_pathCount; i++) {
    CGPathRef path = _paths[i];
    if (CGPathContainsPoint(path, NULL, mapPointAsCGP, FALSE)) {
      isInNYState = YES;
      break;
    }
  }
  
  if (isInNYState)
    [self locationInsideNY];
  else
    [self locationOutsideNY];
}

@end
