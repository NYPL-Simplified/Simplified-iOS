//
//  NSURLRequest+NYPLURLRequestAdditions.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/30/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (NYPLURLRequestAdditions)
+ (instancetype _Nonnull) postRequestWithProblemDocument:(NSDictionary * _Nonnull)problemDocument url:(NSURL * _Nonnull)url;
+ (instancetype _Nonnull) postRequestWithParams:(NSDictionary * _Nonnull)params imageOrNil:(UIImage * _Nullable)image url:(NSURL * _Nonnull)url;
@end
