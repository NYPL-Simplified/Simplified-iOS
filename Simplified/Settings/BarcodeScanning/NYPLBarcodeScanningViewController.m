/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@import PureLayout;
#import <AudioToolbox/AudioToolbox.h>
#import "SimplyE-Swift.h"
#import "NYPLBarcodeScanningViewController.h"

@interface NYPLBarcodeScanningViewController ()

@property (nonatomic, strong) ZXCapture *capture;
@property (nonatomic, copy) void (^completion)(NSString *resultString);
@property (nonatomic) BOOL isFirstApplyOrientation;
@property (nonatomic) UIView *scanRectView;

@end

@implementation NYPLBarcodeScanningViewController {
	CGAffineTransform _captureSizeTransform;
}

- (instancetype)initWithCompletion:(void (^)(NSString *resultString))completion
{
  self = [super init];
  if (self) {
    self.completion = completion;
  }
  return self;
}

- (void)dealloc
{
  [self.capture.layer removeFromSuperlayer];
}

#pragma mark - View Controller Methods

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                   target:self
                                   action:@selector(didSelectCancel)];
  self.navigationItem.leftBarButtonItem = cancelButton;

  self.capture = [[ZXCapture alloc] init];
  if ([self.capture.captureDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]) {
    self.capture.sessionPreset = AVCaptureSessionPreset1920x1080;
  }
  self.capture.camera = self.capture.back;
  self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
  self.capture.delegate = self;
  [self.view.layer addSublayer:self.capture.layer];

  self.scanRectView = [[UIView alloc] init];
  self.scanRectView.layer.borderColor = [UIColor redColor].CGColor;
  self.scanRectView.layer.borderWidth = 4.0;
  self.scanRectView.layer.cornerRadius = 10.0;
  [self.view addSubview:self.scanRectView];

  // kind of arbitrary, but let's use a perceived width minus some padding
  CGFloat dim = MIN(self.view.frame.size.width, self.view.frame.size.height) - 20;
  [self.scanRectView autoSetDimensionsToSize:CGSizeMake(dim, dim/2)];
  [self.scanRectView autoCenterInSuperview];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  if (_isFirstApplyOrientation == NO) {
    _isFirstApplyOrientation = YES;
    [self applyOrientation];
  }
}

- (void)didSelectCancel
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context)
	{
		[self applyOrientation];
	}];
}

#pragma mark - Private
- (void)applyOrientation {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	float scanRectRotation;
	float captureRotation;

	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			captureRotation = 0;
			scanRectRotation = 90;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			captureRotation = 90;
			scanRectRotation = 180;
			break;
		case UIInterfaceOrientationLandscapeRight:
			captureRotation = 270;
			scanRectRotation = 0;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			captureRotation = 180;
			scanRectRotation = 270;
			break;
		default:
			captureRotation = 0;
			scanRectRotation = 90;
			break;
	}
  self.capture.layer.frame = self.view.frame;
	CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat) (captureRotation / 180 * M_PI));
	[self.capture setTransform:transform];
	[self.capture setRotation:scanRectRotation];
  [self applyRectOfInterest:orientation];
}

- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation
{
  CGFloat scaleVideoX, scaleVideoY;
  CGFloat videoSizeX, videoSizeY;
  CGRect transformedVideoRect = self.scanRectView.frame;

  if ([self.capture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
    videoSizeX = 1080;
    videoSizeY = 1920;
  } else {
    videoSizeX = 720;
    videoSizeY = 1280;
  }

  if (UIInterfaceOrientationIsPortrait(orientation)) {
    scaleVideoX = self.capture.layer.frame.size.width / videoSizeX;
    scaleVideoY = self.capture.layer.frame.size.height / videoSizeY;

    // Convert CGPoint under portrait mode to map with orientation of image
    // because the image will be cropped before rotate
    // reference: https://github.com/zxingify/zxingify-objc/issues/222
    CGFloat realX = transformedVideoRect.origin.y;
    CGFloat realY = self.capture.layer.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x;
    CGFloat realWidth = transformedVideoRect.size.height;
    CGFloat realHeight = transformedVideoRect.size.width;
    transformedVideoRect = CGRectMake(realX, realY, realWidth, realHeight);
  } else {
    scaleVideoX = self.capture.layer.frame.size.width / videoSizeY;
    scaleVideoY = self.capture.layer.frame.size.height / videoSizeX;
  }

  _captureSizeTransform = CGAffineTransformMakeScale(1.0/scaleVideoX, 1.0/scaleVideoY);
  self.capture.scanRect = CGRectApplyAffineTransform(transformedVideoRect, _captureSizeTransform);
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result
{
  NYPLLOG_F(@"ZXing result: %@", result);

  if (!result) {
    return;
  }

  [self.capture stop];

  AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

  // send the decoded barcode back
  if (self.completion) {
    self.completion(result.text);
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
