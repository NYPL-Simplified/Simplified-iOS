#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSAcquisition.h"
#import "NYPLOPDSCategory.h"
#import "NYPLOPDSEntryGroupAttributes.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"
#import "NYPLXML.h"
#import "SimplyE-Swift.h"

#import "NYPLOPDSEntry.h"

@interface NYPLOPDSEntry ()

@property (nonatomic) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nonatomic) NSString *alternativeHeadline;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSArray<NYPLOPDSLink *> *authorLinks;
@property (nonatomic) NYPLOPDSLink *seriesLink;
@property (nonatomic) NSArray<NYPLOPDSCategory *> *categories;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSArray *links;
@property (nonatomic) NYPLOPDSLink *annotations;
@property (nonatomic) NYPLOPDSLink *alternate;
@property (nonatomic) NYPLOPDSLink *relatedWorks;
@property (nonatomic) NSURL *analytics;
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
    NSMutableArray<NYPLOPDSLink *> const *authorLinks = [NSMutableArray array];
    
    for(NYPLXML *const authorXML in [entryXML childrenWithName:@"author"]) {
      NYPLXML *const nameXML = [authorXML firstChildWithName:@"name"];
      if(!nameXML) {
        NYPLLOG(@"'author' element missing required 'name' element. Ignoring malformed 'author' element.");
        continue;
      }
      [authorStrings addObject:nameXML.value];
      
      NYPLXML *const authorLinkXML = [authorXML firstChildWithName:@"link"];
      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:authorLinkXML];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element for author.");
      } else if ([link.rel isEqualToString:@"contributor"]) {
        [authorLinks addObject:link];
      }
    }

    self.authorStrings = authorStrings;
    self.authorLinks = [authorLinks copy];
  }
  
  {
    NSMutableArray<NYPLOPDSCategory *> const *categories = [NSMutableArray array];
    
    for(NYPLXML *const categoryXML in [entryXML childrenWithName:@"category"]) {
      NSString *const term = categoryXML.attributes[@"term"];
      if(!term) {
        NYPLLOG(@"Category missing required 'term'.");
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
    NYPLLOG(@"Missing required 'id' element.");
    return nil;
  }
  
  {
    NSMutableArray *const mutableLinks = [NSMutableArray array];
    NSMutableArray<NYPLOPDSAcquisition *> *const mutableAcquisitions = [NSMutableArray array];
    
    for (NYPLXML *const linkXML in [entryXML childrenWithName:@"link"]) {

      // Try parsing the link as an acquisition first to avoid creating an NYPLOPDSLink
      // for no reason.
      if ([[linkXML attributes][@"rel"] containsString:NYPLOPDSRelationAcquisition]) {
        NYPLOPDSAcquisition *const acquisition = [NYPLOPDSAcquisition acquisitionWithLinkXML:linkXML];
        if (acquisition) {
          [mutableAcquisitions addObject:acquisition];
          continue;
        }

        // It may sometimes bet the case that `!acquisition` if the acquisition used a
        // non-standard relation. As such, we do not log an error here and let things
        // continue so the link can be added to `self.links`.
      }

      NYPLOPDSLink *const link = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if(!link) {
        NYPLLOG(@"Ignoring malformed 'link' element.");
        continue;
      }

      if ([link.rel isEqualToString:@"http://www.w3.org/ns/oa#annotationService"]){
        self.annotations = link;
      } else if ([link.rel isEqualToString:@"alternate"]){
        self.alternate = link;
        self.analytics = [NSURL URLWithString:[link.href.absoluteString stringByReplacingOccurrencesOfString:@"/works/" withString:@"/analytics/"]];
      } else if ([link.rel isEqualToString:@"related"]){
        self.relatedWorks = link;
      } else {
        [mutableLinks addObject:link];
      }
    }

    self.acquisitions = [mutableAcquisitions copy];
    self.links = [mutableLinks copy];
  }
  
  self.providerName = [entryXML firstChildWithName:@"distribution"].attributes[@"bibframe:ProviderName"];
  
  {
    NSString *const dateString = [entryXML firstChildWithName:@"issued"].value;
    if(dateString) {
      self.published = [NSDate dateWithISO8601DateString:dateString];
    }
  }
  
  self.publisher = [entryXML firstChildWithName:@"publisher"].value;
  
  self.summary = [entryXML firstChildWithName:@"summary"].value;
  
  if(!((self.title = [entryXML firstChildWithName:@"title"].value))) {
    NYPLLOG(@"Missing required 'title' element.");
    return nil;
  }
  
  {
    NSString *const updatedString = [entryXML firstChildWithName:@"updated"].value;
    if(!updatedString) {
      NYPLLOG(@"Missing required 'updated' element.");
      return nil;
    }
    
    self.updated = [NSDate dateWithRFC3339String:updatedString];
    if(!self.updated) {
      NYPLLOG(@"Element 'updated' does not contain an RFC 3339 date.");
      return nil;
    }
  }

  {
    NYPLXML *const seriesXML = [entryXML firstChildWithName:@"Series"];
    NYPLXML *const linkXML = [seriesXML firstChildWithName:@"link"];
    if (linkXML) {
      self.seriesLink = [[NYPLOPDSLink alloc] initWithXML:linkXML];
      if (!self.seriesLink) {
        NYPLLOG(@"Ignoring malformed 'link' element for schema:Series.");
      }
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
        NYPLLOG(@"Ignoring group link without required 'title' attribute.");
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
