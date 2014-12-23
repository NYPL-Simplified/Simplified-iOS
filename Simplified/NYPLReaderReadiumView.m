#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLReaderView.h"
#import "NYPLReaderViewDelegate.h"
#import "NYPLReadium.h"

#import "NYPLReaderReadiumView.h"

@interface NYPLReaderReadiumView () <RDContainerDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RDContainer *container;

@end

@implementation NYPLReaderReadiumView

- (instancetype)initWithBook:(NYPLBook *const)book
                    delegate:(id<NYPLReaderViewDelegate> const)delegate
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    NYPLLOG(@"Failed to initialize due to nil book.");
    return nil;
  }
  
  self.book = book;
  
  self.delegate = delegate;
  
  @try {
    self.container = [[RDContainer alloc]
                      initWithDelegate:self
                      path:[[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                             fileURLForBookIndentifier:book.identifier]
                            path]];
  } @catch (...) {
    self.bookIsCorrupt = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self.delegate readerView:self didEncounterCorruptionForBook:book];
    }];
  }
  
  return self;
}

#pragma mark RDContainerDelegate

- (void)rdcontainer:(__attribute__((unused)) RDContainer *const)container
     handleSdkError:(__attribute__((unused)) NSString *const)message
{
  // TODO
}

@end
