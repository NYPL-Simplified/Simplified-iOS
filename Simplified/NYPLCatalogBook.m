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

- (id)initWithAcquisition:(NYPLCatalogAcquisition *const)acquisition
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
