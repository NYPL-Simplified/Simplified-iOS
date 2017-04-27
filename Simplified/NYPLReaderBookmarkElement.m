//
//  NYPLReaderBookmarkElement.m
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#import "NYPLReaderBookmarkElement.h"

@interface NYPLReaderBookmarkElement ()

@property (nonatomic) NSString *contentCFI;

// serverAnnotationId will be used to identify which bookmark to delete
// from the server, after an annotation has been created on the server
@property (nonatomic) NSString *serverAnnotationId;

// idref is like the chapter
@property (nonatomic) NSString *idref;

// properties that we will set in NYPLReaderBookmarkCell
@property (nonatomic) NSString *chapterTitle;
@property (nonatomic) NSString *excerpt;
@property (nonatomic) NSString *pageNumber;

@end

@implementation  NYPLReaderBookmarkElement


- (instancetype)initWithCFI:(NSString *)contentCFI andId:(NSString *)serverAnnotationId andIdref:(NSString *)idref
{
    self = [super init];
    if(!self) return nil;
    
    self.contentCFI = contentCFI;
    self.serverAnnotationId = serverAnnotationId;
    self.idref = idref;
    
    self.chapterTitle = @"";
    self.excerpt = @"";
    self.pageNumber = @"";
    
    return self;
}

@end
