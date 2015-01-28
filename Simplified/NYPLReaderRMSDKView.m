#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLRMSDK.h"

#import "NYPLReaderRMSDKView.h"

@interface NYPLReaderRMSDKView () <RMDocumentHostDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RMDocumentHost *documentHost;
@property (nonatomic) CGPoint touchBeganLocation;

@end

static NSString *const renderer = @"rmsdk-10";

static RMServices *services = nil;

static void generateTOCElements(NSArray *const TOCItems,
                                NSUInteger const nestingLevel,
                                NSMutableArray *const TOCElements)
{
  for(RMTOCItem *const TOCItem in TOCItems) {
    NYPLReaderTOCElement *const TOCElement =
      [[NYPLReaderTOCElement alloc]
       initWithOpaqueLocation:((NYPLReaderRendererOpaqueLocation *) TOCItem.location)
       title:TOCItem.title
       nestingLevel:nestingLevel];
    [TOCElements addObject:TOCElement];
    generateTOCElements(TOCItem.children, nestingLevel + 1, TOCElements);
  }
}

@implementation NYPLReaderRMSDKView

- (void)addObservers
{
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsColorSchemeDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsFontFaceDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowDependentSettings)
   name:NYPLReaderSettingsFontSizeDidChangeNotification
   object:nil];
}

- (void)applyCurrentFlowDependentSettings
{
  // TODO
}

- (void)applyCurrentFlowIndependentSettings
{
  // TODO
}

#pragma mark NSObject

+ (void)initialize
{
  services = [[RMServices alloc] initWithProduct:@"Simplified" version:@"0.0"];
}

- (instancetype)initWithFrame:(CGRect const)frame
                         book:(NYPLBook *const)book
                     delegate:(id<NYPLReaderRendererDelegate> const)delegate
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  if(!book) {
    NYPLLOG(@"Failed to initialize due to nil book.");
    return nil;
  }
  
  self.book = book;
  
  self.delegate = delegate;
  
  @try {
    self.documentHost = [[RMDocumentHost alloc]
                         initWithUrl:[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                      fileURLForBookIndentifier:self.book.identifier]
                         mimeType:@"application/epub+zip"
                         width:CGRectGetWidth([UIScreen mainScreen].nativeBounds)
                         height:CGRectGetHeight([UIScreen mainScreen].nativeBounds)
                         delegate:self
                         load:YES];
  } @catch (...) {
    self.bookIsCorrupt = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self.delegate renderer:self didEncounterCorruptionForBook:book];
    }];
  }
  
  NYPLBookLocation *const location = [[NYPLMyBooksRegistry sharedRegistry]
                                      locationForIdentifier:self.book.identifier];
  if([location.renderer isEqualToString:renderer]) {
    [self.documentHost gotoBookmark:location.locationString];
  }
  
  self.multipleTouchEnabled = NO;
  self.contentMode = UIViewContentModeRedraw;
  
  [self addObservers];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIView

- (void)drawRect:(__attribute__((unused)) CGRect)rect
{
  NSUInteger const channels = 4;
  NSUInteger const width = CGRectGetWidth(self.frame) * [UIScreen mainScreen].scale;
  NSUInteger const height = CGRectGetHeight(self.frame) * [UIScreen mainScreen].scale;
  
  NSMutableData *const renderBuffer =
    [NSMutableData dataWithLength:(channels * width * height)];
  
  [self.documentHost setWidth:width height:height];
  [self.documentHost render:renderBuffer];
  
  CGDataProviderRef const provider = CGDataProviderCreateWithCFData((CFDataRef)renderBuffer);
  CGColorSpaceRef const colorSpace = CGColorSpaceCreateDeviceRGB();
  CGImageRef imageRef = CGImageCreate(width,
                                      height,
                                      8,
                                      8 * channels,
                                      width * channels,
                                      colorSpace,
                                      kCGBitmapByteOrderDefault & kCGImageAlphaLast,
                                      provider,
                                      NULL,
                                      false,
                                      kCGRenderingIntentDefault);
  UIImage *const image = [UIImage imageWithCGImage:imageRef];
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  CGImageRelease(imageRef);
  
  [image drawInRect:self.bounds];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(__attribute__((unused)) UIEvent *)event
{
  assert(touches.count == 1);
  
  self.touchBeganLocation = [[touches anyObject] locationInView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(__attribute__((unused)) UIEvent *)event
{
  // This method uses logic equivalent to the logic in "simplified.js".
  
  assert(touches.count == 1);
  
  CGPoint const start = self.touchBeganLocation;
  CGPoint const end = [[touches anyObject] locationInView:self];
  
  if(fabs(end.x - start.x) <= 5.0 && fabs(end.y - start.y) <= 5.0) {
    CGFloat const position = end.x / CGRectGetWidth(self.frame);
    if(position <= 0.2) {
      [self.documentHost previousScreen];
      [self reportLocation];
      [self setNeedsDisplay];
    } else if(position >= 0.8) {
      [self.documentHost nextScreen];
      [self reportLocation];
      [self setNeedsDisplay];
    } else {
      [self.delegate renderer:self didReceiveGesture:NYPLReaderRendererGestureToggleUserInterface];
    }
  } else {
    CGFloat const relativeDistanceX = (end.x - start.x) / CGRectGetWidth(self.frame);
    CGFloat const slope = (end.y - start.y) / (end.x - start.x);
    if(fabs(slope) <= 0.5 && fabs(relativeDistanceX) >= 0.1) {
      if(relativeDistanceX > 0) {
        [self.documentHost previousScreen];
      } else {
        [self.documentHost nextScreen];
      }
      [self reportLocation];
      [self setNeedsDisplay];
    }
  }
}

#pragma mark NYPLReaderRenderer

- (BOOL)loaded
{
  return self.documentHost.loaded;
}

- (void)openOpaqueLocation:(NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  if(!opaqueLocation) {
    NYPLLOG(@"Ignoring nil location.");
    return;
  }
  
  if(![(id)opaqueLocation isKindOfClass:[RMLocation class]]) {
    @throw NSInvalidArgumentException;
  }
  
  [self.documentHost gotoLocation:(RMLocation *)opaqueLocation];
  
  [self reportLocation];
  
  [self setNeedsDisplay];
}

- (NSArray *)TOCElements
{
  NSArray *const TOCItems = self.documentHost.tableOfContents.children;
  
  NSMutableArray *const TOCElements = [NSMutableArray arrayWithCapacity:TOCItems.count];
  
  generateTOCElements(TOCItems, 0, TOCElements);
  
  return TOCElements;
}

#pragma mark -

- (void)reportLocation
{
  NYPLBookLocation *const location = [[NYPLBookLocation alloc]
                                      initWithLocationString:[self.documentHost bookmarkHere]
                                      renderer:renderer];
  
  [[NYPLMyBooksRegistry sharedRegistry]
   setLocation:location
   forIdentifier:self.book.identifier];
}

@end
