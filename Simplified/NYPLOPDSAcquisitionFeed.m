#import "NSDate+NYPLDateAdditions.h"

#import "NYPLOPDSAcquisitionFeed.h"

@interface NYPLOPDSAcquisitionFeed ()

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSAcquisitionFeed

- (id)initWithDocument:(SMXMLDocument *)document
{
  self = [super init];
  if(!self) return nil;
  
  self.identifier = [document.root childNamed:@"id"].value;
  self.title = [document.root childNamed:@"title"].value;
  self.updated = [NSDate dateWithRFC3339:[document.root childNamed:@"updated"].value];

  return self;
}

@end
