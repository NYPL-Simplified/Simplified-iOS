#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRMSDK.h"

#import "NYPLReaderRMSDKView.h"

@interface NYPLReaderRMSDKView () <RMDocumentHostDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RMDocumentHost *documentHost;
@property (nonatomic) BOOL loaded;

@end

static RMServices *services = nil;

@implementation NYPLReaderRMSDKView

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
                         delegate:self];
  } @catch (...) {
    self.bookIsCorrupt = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self.delegate renderer:self didEncounterCorruptionForBook:book];
    }];
  }
  
  return self;
}

#pragma mark NYPLReaderRenderer

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
