//
//  NYPLLocationCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLLocationCardController.h"
#import "NYPLAnimatingButton.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLSettings.h"
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
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *checkButtonBottomConstraint;

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

- (void)configureInitialAppearance
{
  self.checkButton.alpha = 1.0;
  self.statusLabel.text = NSLocalizedString(@"This service is available to New York state residents only.", nil);
  self.continueButton.enabled = NO;
  self.continueButton.alpha = 0.0;
  self.checkButtonBottomConstraint.constant = 0.0;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.isDeterminingLocation = NO;
  
  if (!currentApplication.isInNYState) {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
      self.state = NYPLLocationStateCouldNotDetermine;
    } else {
      self.state = NYPLLocationStateUnknown;
      [self configureInitialAppearance];
    }
  } else {
    self.state = NYPLLocationStateInsideNY;
  }
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
  
  [self.locationManager requestWhenInUseAuthorization];
}

- (void)setIsDeterminingLocation:(BOOL)isDeterminingLocation
{
  if (self.isDeterminingLocation != isDeterminingLocation) {
    _isDeterminingLocation = isDeterminingLocation;
    
    if (isDeterminingLocation) {
      [self.locationManager requestLocation];
    }
  }
}

- (void)locationOutsideNY
{
  self.state = NYPLLocationStateOutsideNY;
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
  if (!self.isDeterminingLocation) {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
      [self.locationManager requestWhenInUseAuthorization];
    } else {
      self.isDeterminingLocation = YES;
    }
  }
}

- (void)setState:(NYPLLocationState)state
{
  CGFloat duration = 0.5;
  
  if (_state != state) {
    _state = state;
    self.currentApplication.isInNYState = (state == NYPLLocationStateInsideNY);
    if (state == NYPLLocationStateUnknown) {
      [self configureInitialAppearance];
      
    } else if (state == NYPLLocationStateOutsideNY) {
      self.checkButtonBottomConstraint.constant = -(self.continueButton.frame.size.height + 8.0);
      [UIView animateWithDuration:duration
                       animations:^{
                         self.continueButton.alpha = 1.0;
                         self.checkButton.alpha = 1.0;
                         self.statusLabel.text = NSLocalizedString(@"You're outside New York State. You can still apply for a card, but you won't be able to borrow books until it arrives.", nil);
                         [self.view setNeedsLayout];
                       } completion:^(BOOL finished) {
                         if (finished) {
                           [self.continueButton setEnabled:YES];
                         }
                       }];
      
    } else if (state == NYPLLocationStateInsideNY) {
      [UIView transitionWithView:self.statusLabel
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
                        self.statusLabel.text = NSLocalizedString(@"Hello New York! You're good to go", nil);
                      } completion:nil];
      [UIView animateWithDuration:duration
                       animations:^{
                         self.checkButton.alpha = 0.0;
                         self.continueButton.alpha = 1.0;
                       }];
      [UIView transitionWithView:self.imageView
                        duration:duration
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
                        self.imageView.image = [UIImage imageNamed:s_checkmarkImageName];
                      } completion:^(BOOL finished) {
                        if (finished) {
                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((duration/2.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self.continueButton setEnabled:YES];
                          });
                        }
                      }];
      
    } else if (state == NYPLLocationStateCouldNotDetermine) {
      self.checkButtonBottomConstraint.constant = -(self.continueButton.frame.size.height + 8.0);
      [UIView animateWithDuration:duration
                       animations:^{
                         self.continueButton.alpha = 1.0;
                         self.checkButton.alpha = 1.0;
                         self.statusLabel.text = NSLocalizedString(@"Could not determine your location. You can still apply for a card, but you won't be able to borrow books until it arrives.", nil);
                         [self.view setNeedsLayout];
                       } completion:^(BOOL finished) {
                         if (finished) {
                           [self.continueButton setEnabled:YES];
                         }
                       }];
      
    }
  }
}

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
    self.state = NYPLLocationStateCouldNotDetermine;
}

- (void) locationManager:(__attribute__((unused)) CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
  if (self.isDeterminingLocation) {
    self.isDeterminingLocation = NO;
    
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
}

@end
