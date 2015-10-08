//
//  NYPLLocationCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLLocationCardController.h"
#import "CJAMacros.h"
@import CoreLocation;

static NSString *s_checkmarkImageName = @"Check";

@interface NYPLLocationCardController () <CLLocationManagerDelegate> {
  CGPathRef *_paths;
  size_t _pathCount;
}
@property (nonatomic, assign) BOOL shouldRequestLocation;
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
  self.shouldRequestLocation = YES;
  self.successLabel.alpha = 0;
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

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (self.shouldRequestLocation) {
    self.shouldRequestLocation = NO;
    
    // Get the user's location
    if (nil == self.locationManager) {
      self.locationManager = [[CLLocationManager alloc] init];
      
      self.locationManager.delegate = self;
      self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(NSFoundationVersionNumber_iOS_8_0)) {
      [self.locationManager requestLocation];
    } else {
      self.requestingContinuousUpdates = YES;
      [self.locationManager startUpdatingLocation];
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
  __weak NYPLCardApplicationViewController *weakSelf = self;
  [UIView transitionWithView:self.imageView
                    duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight
                  animations:^{
                    self.imageView.image = [UIImage imageNamed:s_checkmarkImageName];
                  } completion:^(BOOL finished) {
                    if (finished) {
                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf performSegueWithIdentifier:@"photo" sender:nil];
                      });
                    }
                  }];
  [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    self.successLabel.alpha = 1.0;
    self.continueButton.alpha = 1.0;
  } completion:nil];
}

- (IBAction)continueToPhoto:(__attribute__((unused)) id)sender
{
  [self performSegueWithIdentifier:@"photo" sender:nil];
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
  if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied)
    [self couldNotDetermineLocation];
}

- (void) locationManager:(__attribute__((unused)) CLLocationManager *)manager didFailWithError:(__attribute__((unused)) NSError *)error
{
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
