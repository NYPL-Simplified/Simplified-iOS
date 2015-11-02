//
//  NYPLProblemDocument.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NYPLProblemDocument : NSObject
@property (nonatomic, readonly) NSString *type, *title, *detail;
+ (instancetype)problemDocumentWithData:(NSData *)rawJSONData;
+ (instancetype)problemDocumentWithDictionary:(NSDictionary *)jsonObject;
@end
