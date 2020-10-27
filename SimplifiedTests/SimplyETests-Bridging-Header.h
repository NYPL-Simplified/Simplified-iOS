//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "SimplyE-Bridging-Header.h"
#import "NYPLOpenSearchDescription.h"
#import "NSString+NYPLStringAdditions.h"
#import "NYPLBook.h"

//
// Override here any ObjC declarations to facilitate testing
//

@interface NYPLOpenSearchDescription ()
@property (nonatomic, readwrite) NSString *OPDSURLTemplate;
@end

@interface NSDate ()
+ (NSDate *)dateWithISO8601DateStringDeprecated:(NSString *const)string;
@end

@interface UIColor ()
- (NSString *)javascriptHexString;
@end

@interface NYPLBook ()
- (nonnull instancetype)initWithAcquisitions:(nonnull NSArray<NYPLOPDSAcquisition *> *)acquisitions
                                 bookAuthors:(nullable NSArray<NYPLBookAuthor *> *)authors
                             categoryStrings:(nullable NSArray *)categoryStrings
                                 distributor:(nullable NSString *)distributor
                                  identifier:(nonnull NSString *)identifier
                                    imageURL:(nullable NSURL *)imageURL
                           imageThumbnailURL:(nullable NSURL *)imageThumbnailURL
                                   published:(nullable NSDate *)published
                                   publisher:(nullable NSString *)publisher
                                    subtitle:(nullable NSString *)subtitle
                                     summary:(nullable NSString *)summary
                                       title:(nonnull NSString *)title
                                     updated:(nonnull NSDate *)updated
                              annotationsURL:(nullable NSURL *) annotationsURL
                                analyticsURL:(nullable NSURL *)analyticsURL
                                alternateURL:(nullable NSURL *)alternateURL
                             relatedWorksURL:(nullable NSURL *)relatedWorksURL
                                   seriesURL:(nullable NSURL *)seriesURL
                                   revokeURL:(nullable NSURL *)revokeURL
                                   reportURL:(nullable NSURL *)reportURL;
@end
