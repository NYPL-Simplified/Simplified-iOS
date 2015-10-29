//
//  NYPLProblemDocument.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLProblemDocument.h"

@interface NYPLProblemDocument ()
@property (nonatomic, strong) NSString *type, *title, *detail;
@end

@implementation NYPLProblemDocument
+ (instancetype)problemDocumentWithData:(NSData *)rawJSONData
{
  NSError *jsonError = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:rawJSONData options:0 error:&jsonError];
  if (!jsonError) {
    return [self problemDocumentWithDictionary:jsonObject];
  }
  return nil;
}

+ (instancetype)problemDocumentWithDictionary:(NSDictionary *)jsonObject
{
  NYPLProblemDocument *document = [[NYPLProblemDocument alloc] init];
  document.type = jsonObject[@"type"];
  document.title = jsonObject[@"title"];
  document.detail = jsonObject[@"detail"];
  return document;
}

@end
