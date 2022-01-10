//
//  NSURL+NYPLURLAdditions.h
//  Simplified
//
//  Created by Sam Tarakajian on 9/24/15.
//  Copyright © 2015 NYPL. All rights reserved.
//

@interface NSURL (NYPLURLAdditions)

@property (nonatomic, readonly, assign) BOOL isNYPLExternal;

- (NSURL *)URLBySwappingForScheme:(NSString *)scheme;

@end
