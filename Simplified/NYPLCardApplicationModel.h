//
//  NYPLCardApplicationModel.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NYPLAssetUploadState) {
  NYPLAssetUploadStateUnknown              = 0,
  NYPLAssetUploadStateUploading,
  NYPLAssetUploadStateError,
  NYPLAssetUploadStateComplete
};

@interface NYPLCardApplicationModel : NSObject <NSCoding>
@property (nonatomic, readonly) NSURL *apiURL;

@property (nonatomic, strong) NSDate *dob;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) NSString *awsPhotoName;
@property (nonatomic, assign) BOOL isInNYState;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, assign, readonly) NYPLAssetUploadState applicationUploadState, photoUploadState;

+ (NYPLCardApplicationModel *) currentCardApplication;
+ (NYPLCardApplicationModel *) beginCardApplication;

- (void)uploadPhoto;
- (void)uploadApplication;
- (void)cancelApplicationUpload;
@end
