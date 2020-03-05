#import "NYPLAttributedString.h"

NSAttributedString *NYPLAttributedStringForAuthorsFromString(NSString *string)
{
  if(!string) return nil;
  
  NSMutableParagraphStyle *const paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineSpacing = 0.0;
  paragraphStyle.minimumLineHeight = 0.0;
  paragraphStyle.lineHeightMultiple = 0.9;
  paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
  paragraphStyle.hyphenationFactor = 0.85;
  
  return [[NSAttributedString alloc]
          initWithString:string
          attributes:@{NSParagraphStyleAttributeName: paragraphStyle}];
}

NSAttributedString *NYPLAttributedStringForTitleFromString(NSString *string)
{
  if(!string) return nil;
  
  NSMutableParagraphStyle *const paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineSpacing = 0.0;
  paragraphStyle.minimumLineHeight = 0.0;
  paragraphStyle.lineHeightMultiple = 0.85;
  paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
  paragraphStyle.hyphenationFactor = 0.75;
  
  return [[NSAttributedString alloc]
          initWithString:string
          attributes:@{NSParagraphStyleAttributeName: paragraphStyle}];
}