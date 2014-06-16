#import "NYPLCatalogBook.h"

@interface NYPLCatalogBook ()

@property (nonatomic) NYPLCatalogAcquisitions *acquisitions;
@property (nonatomic) NSArray *authorStrings;
@property (nonatomic) NSURL *collectionURL; // nilable
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSURL *imageURL; // nilable
@property (nonatomic) NSURL *imageThumbnailURL; // nilable
@property (nonatomic) NSString *title;
@property (nonatomic) NSDate *updated;

@end

@implementation NYPLCatalogBook

- (id)initWithAcquisitions:(NYPLCatalogAcquisitions *const)acquisitions
             authorStrings:(NSArray *const)authorStrings
             collectionURL:(NSURL *const)collectionURL
                identifier:(NSString *const)identifier
                  imageURL:(NSURL *const)imageURL
         imageThumbnailURL:(NSURL *const)imageThumbnailURL
                     title:(NSString *const)title
                   updated:(NSDate *const)updated
{
  self = [super init];
  if(!self) return nil;
  
  if(!(acquisitions && authorStrings && identifier && title && updated)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in authorStrings) {
    if(![object isKindOfClass:[NSString class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.acquisitions = acquisitions;
  self.authorStrings = authorStrings;
  self.collectionURL = collectionURL;
  self.identifier = identifier;
  self.imageURL = imageURL;
  self.imageThumbnailURL = imageThumbnailURL;
  self.title = title;
  self.updated = updated;
  
  return self;
}

@end
