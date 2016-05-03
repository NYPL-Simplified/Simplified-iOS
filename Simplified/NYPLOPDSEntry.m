#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSCategory.h"
#import "NYPLOPDSEntryGroupAttributes.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLXML.h"

#import "NYPLOPDSEntry.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSString *alternativeHeadline;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSArray<NYPLOPDSCategory *> *categories;
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
        NYPLLOG(@"warning", kNYPLInvalidEntryException, nil, @"'author' element missing required 'name' element. Ignoring malformed 'author' element.");
        continue;
      }
      [authorStrings addObject:nameXML.value];
    }

    self.authorStrings = authorStrings;
  }
  
  {
    NSMutableArray<NYPLOPDSCategory *> const *categories = [NSMutableArray array];
    
    for(NYPLXML *const categoryXML in [entryXML childrenWithName:@"category"]) {
      NSString *const term = categoryXML.attributes[@"term"];
      if(!term) {
        NYPLLOG(@"warning", kNYPLInvalidEntryException, nil, @"Category missing required 'term'.");
        continue;
      }
      NSString *const schemeString = categoryXML.attributes[@"scheme"];
      NSURL *const scheme = schemeString ? [NSURL URLWithString:schemeString] : nil;
      [categories addObject:[NYPLOPDSCategory
                             categoryWithTerm:term
                             label:categoryXML.attributes[@"label"]
                             scheme:scheme]];
    }
    
    self.categories = [categories copy];
  }
  
  if(!((self.identifier = [entryXML firstChildWithName:@"id"].value))) {
    NYPLLOG(@"warning", kNYPLInvalidEntryException, nil, @"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const links = [NSMutableArray array];
    
    for(NYPLXML *const linkXML in [entryXML childrenWithName:@"link"]) {
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if(!link) {
        NYPLLOG(@"warning", kNYPLInvalidEntryException, @{@"identifier":self.identifier}, @"Ignoring malformed 'link' element.");
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
    NYPLLOG(@"warning", kNYPLInvalidEntryException, @{@"identifier":self.identifier}, @"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [entryXML firstChildWithName:@"updated"].value;
    if(!updatedString) {
      NYPLLOG(@"warning", kNYPLInvalidEntryException, @{@"identifier":self.identifier}, @"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339String:updatedString];
    if(!self.updated) {
      NYPLLOG(@"warning", kNYPLInvalidEntryException, @{@"identifier":self.identifier}, @"Element 'updated' does not contain an RFC 3339 date.");
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
        NYPLLOG(@"warning", kNYPLInvalidEntryException, @{@"identifier":self.identifier}, @"Ignoring group link without required 'title' attribute.");
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
