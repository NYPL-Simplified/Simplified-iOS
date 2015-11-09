#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSEntryGroupAttributes.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLXML.h"

#import "NYPLOPDSEntry.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSString *alternativeHeadline;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSArray *categoryStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *providerName;
@property (nonatomic) NSDate *published;
@property (nonatomic) NSString *publisher;
@property (nonatomic) NSString *summary;
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLOPDSEntry

- (instancetype)initWithXML:(NYPLXML *const)entryXML
{
  self = [super init];
  if(!self) return nil;

  self.alternativeHeadline = [entryXML firstChildWithName:@"alternativeHeadline"].value;
  
  {
    NSMutableArray *const authorStrings = [NSMutableArray array];
    
    for(NYPLXML *const authorXML in [entryXML childrenWithName:@"author"]) {
      NYPLXML *const nameXML = [authorXML firstChildWithName:@"name"];
      if(!nameXML) {
        NYPLLOG(@"info", @"'author' element missing required 'name' element.");
        NYPLLOG(@"warning", @"Ignoring malformed 'author' element.");
        continue;
      }
      [authorStrings addObject:nameXML.value];
    }

    self.authorStrings = authorStrings;
  }
  
  {
    NSMutableArray *const categoryStrings = [NSMutableArray array];
    
    for(NYPLXML *const categoryXML in [entryXML childrenWithName:@"category"]) {
      NSString *const label = categoryXML.attributes[@"label"];
      NSString *const term = categoryXML.attributes[@"term"];
      if(label) {
        [categoryStrings addObject:label];
      } else if (term && ![NSURL URLWithString:term]) {
        [categoryStrings addObject:term];
      }
    }
    
    self.categoryStrings = categoryStrings;
  }
  
  if(!((self.identifier = [entryXML firstChildWithName:@"id"].value))) {
    NYPLLOG(@"info", @"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(NYPLXML *const linkXML in [entryXML childrenWithName:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if(!link) {
        NYPLLOG(@"warning", @"Ignoring malformed 'link' element.");
        continue;
      }
      [links addObject:link];
    }
    
    self.links = links;
  }
  
  self.providerName = [entryXML firstChildWithName:@"distribution"].attributes[@"bibframe:ProviderName"];
  
  {
    NSString *const dateString = [entryXML firstChildWithName:@"published"].value;
    if(dateString) {
      self.published = [NSDate dateWithRFC3339String:dateString];
    }
  }
  
  self.publisher = [entryXML firstChildWithName:@"publisher"].value;
  
  self.summary = [entryXML firstChildWithName:@"summary"].value;
  
  if(!((self.title = [entryXML firstChildWithName:@"title"].value))) {
    NYPLLOG(@"info", @"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [entryXML firstChildWithName:@"updated"].value;
    if(!updatedString) {
      NYPLLOG(@"info", @"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339String:updatedString];
    if(!self.updated) {
      NYPLLOG(@"info", @"Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }
  
  return self;
}

- (NYPLOPDSEntryGroupAttributes *)groupAttributes
{
  for(NYPLOPDSLink *const link in self.links) {
    if([link.rel isEqualToString:NYPLOPDSRelationGroup]) {
      NSString *const title = link.attributes[@"title"];
      if(!title) {
        NYPLLOG(@"warning", @"Ignoring group link without required 'title' attribute.");
        continue;
      }
      return [[NYPLOPDSEntryGroupAttributes alloc]
              initWithHref:[NSURL URLWithString:link.attributes[@"href"]]
              title:title];
    }
  }
  
  return nil;
}

@end
