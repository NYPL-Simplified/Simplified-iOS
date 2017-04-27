//
//  NYPLReaderBookmarkElement.h
//  Simplified
//
//  Created by Vui Nguyen on 3/28/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

@interface  NYPLReaderBookmarkElement : NSObject

@property (nonatomic, readonly) NSString *contentCFI;

// serverAnnotationId will be used to identify which bookmark to delete
// from the server, after an annotation has been created on the server
@property (nonatomic, readonly) NSString *serverAnnotationId;

// idref is like the chapter
@property (nonatomic, readonly) NSString *idref;


// properties that we will set in NYPLReaderBookmarkCell
@property (nonatomic, readonly) NSString *chapterTitle;
@property (nonatomic, readonly) NSString *excerpt;
@property (nonatomic, readonly) NSString *pageNumber;


- (instancetype)initWithCFI:(NSString *)CFI andId:(NSString *)annotationId andIdref:(NSString *)idref;

@end
