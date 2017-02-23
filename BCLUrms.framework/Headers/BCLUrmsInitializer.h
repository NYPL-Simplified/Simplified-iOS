//
//  BCLUrmsInitializer.h
//  BCLUrms
//
//  Created by Shane Meyer on 7/22/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
	@brief This class must be called to initialize the URMS framework prior to other API calls.
*/
@interface BCLUrmsInitializer : NSObject

/**
	@brief Initializes the URMS framework.
	@param apiKey The API key.
	@param marlinURL The Marlin URL.
*/
+ (void)initializeWithApiKey:(nonnull NSString *)apiKey marlinURL:(nonnull NSString *)marlinURL;

@end
