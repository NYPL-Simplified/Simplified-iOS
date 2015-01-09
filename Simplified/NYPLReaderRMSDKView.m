#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRMSDK.h"

#import "NYPLReaderRMSDKView.h"

@interface NYPLReaderRMSDKView () <RMDocumentHostDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RMDocumentHost *documentHost;

@end

static RMServices *services = nil;

@implementation NYPLReaderRMSDKView

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
  
  self.contentMode = UIViewContentModeRedraw;
  
  return self;
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

#pragma mark NYPLReaderRenderer

- (BOOL)loaded
{
  return self.documentHost.loaded;
}

- (void)openOpaqueLocation:(__attribute__((unused))
                            NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  // TODO: Check if |[opaqueLocation isKindOfClass:[SomeClass class]]|, else throw
  // |NSInvalidArgumentException|.
  
  // TODO: Open location.
}

- (NSArray *)TOCElements
{
  // TODO
  
  return nil;
}

@end
