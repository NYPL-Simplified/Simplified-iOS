#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"

#import "NYPLCatalogBook.h"

@interface NYPLCatalogBook ()

@property (nonatomic) NYPLCatalogAcquisition *acquisition;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSURL *imageURL; // nilable
@property (nonatomic) NSURL *imageThumbnailURL; // nilable
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLCatalogBook

+ (NYPLCatalogBook *)bookWithEntry:(NYPLOPDSEntry *const)entry
{
  if(!entry) {
    NYPLLOG(@"Failed to create book from nil entry.");
    return nil;
  }
  
  NSURL *borrow, *generic, *openAccess, *sample, *image, *imageThumbnail = nil;
  
  for(NYPLOPDSLink *const link in entry.links) {
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisition]) {
      generic = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionBorrow]) {
      borrow = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionOpenAccess]) {
      openAccess = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationAcquisitionSample]) {
      sample = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationImage]) {
      image = link.href;
      continue;
    }
    if([link.rel isEqualToString:NYPLOPDSRelationImageThumbnail]) {
      imageThumbnail = link.href;
      continue;
    }
  }
  
  return [[NYPLCatalogBook alloc]
          initWithAcquisition:[[NYPLCatalogAcquisition alloc]
                               initWithBorrow:borrow
                               generic:generic
                               openAccess:openAccess
                               sample:sample]
          authorStrings:entry.authorStrings
          identifier:entry.identifier
          imageURL:image
          imageThumbnailURL:imageThumbnail
          title:entry.title
          updated:entry.updated];
}

- (instancetype)initWithAcquisition:(NYPLCatalogAcquisition *const)acquisition
                      authorStrings:(NSArray *const)authorStrings
                         identifier:(NSString *const)identifier
                           imageURL:(NSURL *const)imageURL
                  imageThumbnailURL:(NSURL *const)imageThumbnailURL
                              title:(NSString *const)title
                            updated:(NSDate *const)updated
{
  self = [super init];
  if(!self) return nil;
  
  if(!(acquisition && authorStrings && identifier && title && updated)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in authorStrings) {
    if(![object isKindOfClass:[NSString class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.acquisition = acquisition;
  self.authorStrings = authorStrings;
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.title = title;
  self.updated = updated;
  
  return self;
}

@end
