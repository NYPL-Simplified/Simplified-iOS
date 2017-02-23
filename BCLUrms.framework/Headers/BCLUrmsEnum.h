//
//  BCLUrmsEnum.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BCLUrmsErrorCode) {
	/// An error involving the creation of a URMS profile.
	BCLUrmsErrorCodeCreateProfile,
	/// An error involving initialization.
	BCLUrmsErrorCodeInitialization,
	/// An error involving the evaluation of a book's license.
	BCLUrmsErrorCodeLicenseInvalid,
	/// An error representing a URMS profile not being found.
	BCLUrmsErrorCodeProfileNotFound,
	/// An error involving registration of a book.
	BCLUrmsErrorCodeRegisterBook,
	/// An error involving switching URMS profiles.
	BCLUrmsErrorCodeSwitchProfile,
};
