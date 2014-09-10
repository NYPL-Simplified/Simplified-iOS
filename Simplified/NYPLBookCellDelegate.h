#import "NYPLBookCell.h"

@interface NYPLBookCellDelegate : NSObject <NYPLBookCellDelegate>

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedDelegate;

@end
