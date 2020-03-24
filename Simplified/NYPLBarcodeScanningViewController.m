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

@end

@implementation NYPLBarcodeScanningViewController {
	CGAffineTransform _captureSizeTransform;
}

- (instancetype)initWithCompletion:(void (^)(NSString *resultString))completion
{
  self = [super init];
  if (self) {
    self.completion = completion;
    return self;
  } else {
    return nil;
  }
}

#pragma mark - View Controller Methods

- (void)dealloc {
  [self.capture.layer removeFromSuperlayer];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(didSelectCancel)];
  self.navigationItem.leftBarButtonItem = cancelButton;

  self.capture = [[ZXCapture alloc] init];
  self.capture.camera = self.capture.back;
  self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
  [self.view.layer addSublayer:self.capture.layer];

  UIView *previewRect = [[UIView alloc] init];
  previewRect.layer.borderColor = [UIColor redColor].CGColor;
  previewRect.layer.borderWidth = 4.0;
  previewRect.layer.cornerRadius = 20.0;
  [self.view addSubview:previewRect];
  [previewRect autoCenterInSuperview];
  if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    [previewRect autoSetDimensionsToSize:CGSizeMake(350, 170)];
  } else {
    [previewRect autoSetDimensionsToSize:CGSizeMake(250, 120)];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.capture.delegate = self;
  [self applyOrientation];
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
	[self applyRectOfInterest:orientation];
	CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat) (captureRotation / 180 * M_PI));
	[self.capture setTransform:transform];
	[self.capture setRotation:scanRectRotation];
	self.capture.layer.frame = self.view.frame;
}

- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation {
	CGFloat scaleVideo, scaleVideoX, scaleVideoY;
	CGFloat videoSizeX, videoSizeY;
	CGRect transformedVideoRect = self.view.frame;
	if([self.capture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
		videoSizeX = 1080;
		videoSizeY = 1920;
	} else {
		videoSizeX = 720;
		videoSizeY = 1280;
	}
	if(UIInterfaceOrientationIsPortrait(orientation)) {
		scaleVideoX = self.view.frame.size.width / videoSizeX;
		scaleVideoY = self.view.frame.size.height / videoSizeY;
		scaleVideo = MAX(scaleVideoX, scaleVideoY);
		if(scaleVideoX > scaleVideoY) {
			transformedVideoRect.origin.y += (scaleVideo * videoSizeY - self.view.frame.size.height) / 2;
		} else {
			transformedVideoRect.origin.x += (scaleVideo * videoSizeX - self.view.frame.size.width) / 2;
		}
	} else {
		scaleVideoX = self.view.frame.size.width / videoSizeY;
		scaleVideoY = self.view.frame.size.height / videoSizeX;
		scaleVideo = MAX(scaleVideoX, scaleVideoY);
		if(scaleVideoX > scaleVideoY) {
			transformedVideoRect.origin.y += (scaleVideo * videoSizeX - self.view.frame.size.height) / 2;
		} else {
			transformedVideoRect.origin.x += (scaleVideo * videoSizeY - self.view.frame.size.width) / 2;
		}
	}
	_captureSizeTransform = CGAffineTransformMakeScale(1/scaleVideo, 1/scaleVideo);
	self.capture.scanRect = CGRectApplyAffineTransform(transformedVideoRect, _captureSizeTransform);
}

#pragma mark - Private Methods

- (NSString *)barcodeFormatToString:(ZXBarcodeFormat)format {
  switch (format) {
    case kBarcodeFormatAztec:
      return @"Aztec";

    case kBarcodeFormatCodabar:
      return @"CODABAR";

    case kBarcodeFormatCode39:
      return @"Code 39";

    case kBarcodeFormatCode93:
      return @"Code 93";

    case kBarcodeFormatCode128:
      return @"Code 128";

    case kBarcodeFormatDataMatrix:
      return @"Data Matrix";

    case kBarcodeFormatEan8:
      return @"EAN-8";

    case kBarcodeFormatEan13:
      return @"EAN-13";

    case kBarcodeFormatITF:
      return @"ITF";

    case kBarcodeFormatPDF417:
      return @"PDF417";

    case kBarcodeFormatQRCode:
      return @"QR Code";

    case kBarcodeFormatRSS14:
      return @"RSS 14";

    case kBarcodeFormatRSSExpanded:
      return @"RSS Expanded";

    case kBarcodeFormatUPCA:
      return @"UPCA";

    case kBarcodeFormatUPCE:
      return @"UPCE";

    case kBarcodeFormatUPCEANExtension:
      return @"UPC/EAN extension";

    default:
      return @"Unknown";
  }
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)__unused capture result:(ZXResult *)result {
  if (!result) return;

	CGAffineTransform inverse = CGAffineTransformInvert(_captureSizeTransform);
	NSMutableArray *points = [[NSMutableArray alloc] init];
	NSString *location = @"";
	for (ZXResultPoint *resultPoint in result.resultPoints) {
		CGPoint cgPoint = CGPointMake(resultPoint.x, resultPoint.y);
		CGPoint transformedPoint = CGPointApplyAffineTransform(cgPoint, inverse);
		transformedPoint = [self.view convertPoint:transformedPoint toView:self.view.window];
		NSValue* windowPointValue = [NSValue valueWithCGPoint:transformedPoint];
		location = [NSString stringWithFormat:@"%@ (%f, %f)", location, transformedPoint.x, transformedPoint.y];
		[points addObject:windowPointValue];
	}

  // We got a result. Close the window and send the format string back to the delegate.

  NSString *formatString = [self barcodeFormatToString:result.barcodeFormat];
  NSString *display = [NSString stringWithFormat:@"Scanned! Format: %@  Contents: %@  Location: %@", formatString, result.text, location];
  NYPLLOG(display);
  // Vibrate
  AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

  [self.capture stop];

  if (self.completion) {
    self.completion(result.text);
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
