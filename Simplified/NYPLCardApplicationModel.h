//
//  NYPLCardApplicationModel.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NYPLCardApplicationError) {
  NYPLCardApplicationNoError              = 0,
  NYPLCardApplicationErrorTooYoung,
  NYPLCardApplicationErrorNoLocation,
  NYPLCardApplicationErrorNotInNY,
  NYPLCardApplicationErrorNoCamera
};

@interface NYPLCardApplicationModel : NSObject <NSCoding>
@property (nonatomic, readonly) NSURL *apiURL;
@property (nonatomic, assign) NYPLCardApplicationError error;
@property (nonatomic, strong) NSDate *dob;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) NSString *awsPhotoName;
@property (nonatomic, assign) BOOL isInNYState;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, assign, readonly) BOOL applicationSent, photoSent;

- (void)uploadPhoto;
- (void)uploadApplication;
@end
