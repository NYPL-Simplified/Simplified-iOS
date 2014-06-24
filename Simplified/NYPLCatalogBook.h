#import "NYPLCatalogAcquisition.h"
#import "NYPLOPDSEntry.h"

@interface NYPLCatalogBook : NSObject

@property (nonatomic, readonly) NYPLCatalogAcquisition *acquisition;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

+ (NYPLCatalogBook *)bookWithEntry:(NYPLOPDSEntry *)entry;

// designated initializer
- (instancetype)initWithAcquisition:(NYPLCatalogAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                              title:(NSString *)title
                            updated:(NSDate *)updated;

@end
