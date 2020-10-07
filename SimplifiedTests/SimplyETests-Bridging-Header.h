//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "SimplyE-Bridging-Header.h"
#import "NYPLOpenSearchDescription.h"
#import "NSString+NYPLStringAdditions.h"

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
