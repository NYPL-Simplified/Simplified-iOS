//
//  NYPLBarcodeTextMask.m
//  Simplified
//
//  Created by Sam Tarakajian on 11/24/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLBarcodeTextMask.h"

@implementation NYPLBarcodeTextMask

#pragma mark - NSCopying

- (instancetype)copyWithZone:(__unused NSZone *)zone {
  __typeof__(self) mycopy = [[self.class alloc] init];
  return mycopy;
}

#pragma mark - Masking

- (BOOL)shouldChangeText:(__unused NSString *)text withReplacementString:(__unused NSString *)string inRange:(__unused NSRange)range {
  return YES;
}

- (NSString *)filteredStringFromString:(NSString *)string cursorPosition:(NSUInteger *)cursorPosition {
  NSUInteger originalCursorPosition = cursorPosition == NULL ? 0 : *cursorPosition;
  NSMutableString *digitsOnlyString = [NSMutableString new];
  for (NSUInteger i=0; i<[string length]; i++) {
    unichar characterToAdd = [string characterAtIndex:i];
    if (isdigit(characterToAdd)) {
      NSString *stringToAdd = [NSString stringWithCharacters:&characterToAdd length:1];
      
      [digitsOnlyString appendString:stringToAdd];
    }
    else {
      if (i < originalCursorPosition) {
        if (cursorPosition != NULL)
          (*cursorPosition)--;
      }
    }
  }
  
  return digitsOnlyString;
  
}

- (NSString *)formattedStringFromString:(NSString *)string cursorPosition:(NSUInteger *)cursorPosition {
  NSMutableString *stringWithAddedSpaces = [NSMutableString new];
  NSUInteger cursorPositionInSpacelessString = cursorPosition ? *cursorPosition : 0;
  for (NSUInteger i=0; i<[string length]; i++) {
    if ((i==1) || (i==5) || (i==10) || (i==14)) {
      [stringWithAddedSpaces appendString:@" "];
      if (i < cursorPositionInSpacelessString) {
        (*cursorPosition)++;
      }
    }
    unichar characterToAdd = [string characterAtIndex:i];
    NSString *stringToAdd =
    [NSString stringWithCharacters:&characterToAdd length:1];
    
    [stringWithAddedSpaces appendString:stringToAdd];
  }
  
  return stringWithAddedSpaces;
}

@end
