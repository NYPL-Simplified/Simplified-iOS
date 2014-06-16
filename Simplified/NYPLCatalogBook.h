@import Foundation;

#import "NYPLCatalogAcquisitions.h"

@interface NYPLCatalogBook : NSObject

@property (nonatomic, readonly) NYPLCatalogAcquisitions *acquisitions;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSURL *collectionURL; // nilable
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

// designated initializer
- (id)initWithAcquisitions:(NYPLCatalogAcquisitions *)acquisitions
             authorStrings:(NSArray *)authorStrings
             collectionURL:(NSURL *)collectionURL
                identifier:(NSString *)identifier
                  imageURL:(NSURL *)imageURL
         imageThumbnailURL:(NSURL *)imageThumbnailURL
                     title:(NSString *)title
                   updated:(NSDate *)updated;

@end
