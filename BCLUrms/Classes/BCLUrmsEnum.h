//
//  BCLUrmsEnum.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BCLUrmsErrorCode) {
	BCLUrmsErrorCodeCreateProfile,
	BCLUrmsErrorCodeInitialization,
	BCLUrmsErrorCodeLicenseInvalid,
	BCLUrmsErrorCodeProfileNotFound,
	BCLUrmsErrorCodeRegisterBook,
	BCLUrmsErrorCodeSwitchProfile,
};
