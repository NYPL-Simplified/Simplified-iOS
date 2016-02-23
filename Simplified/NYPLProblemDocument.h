#import <Foundation/Foundation.h>

static NSString *const NYPLProblemDocumentTypeNoActiveLoan =
  @"http://librarysimplified.org/terms/problem/no-active-loan";

@interface NYPLProblemDocument : NSObject

@property (nonatomic, readonly) NSString *type, *title, *detail;

+ (instancetype)problemDocumentWithData:(NSData *)rawJSONData;
+ (instancetype)problemDocumentWithDictionary:(NSDictionary *)jsonObject;

@end
