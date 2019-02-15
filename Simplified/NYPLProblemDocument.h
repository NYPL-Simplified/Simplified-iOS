#import <Foundation/Foundation.h>

static NSString *const NYPLProblemDocumentTypeNoActiveLoan =
  @"http://librarysimplified.org/terms/problem/no-active-loan";
static NSString *const NYPLProblemDocumentTypeLoanAlreadyExists =
  @"http://librarysimplified.org/terms/problem/loan-already-exists";

@interface NYPLProblemDocument : NSObject

@property (nonatomic, readonly) NSString *type, *title, *detail;

+ (instancetype)problemDocumentWithData:(NSData *)rawJSONData;
+ (instancetype)problemDocumentWithDictionary:(NSDictionary *)jsonObject;

@end
