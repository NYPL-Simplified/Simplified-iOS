#import "NYPLOPDSEntry.h"

#import "NYPLOPDSGroup.h"

@interface NYPLOPDSGroup ()

@property (nonatomic) NSArray *entries;
@property (nonatomic) NSURL *href;
@property (nonatomic) NSString *title;

@end

@implementation NYPLOPDSGroup

- (instancetype)initWithEntries:(NSArray *const)entries
                           href:(NSURL *const)href
                          title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(entries && href && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in entries) {
    if(![object isKindOfClass:[NYPLOPDSEntry class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.entries = entries;
  self.href = href;
  self.title = [title copy];
  
  return self;
}

@end
