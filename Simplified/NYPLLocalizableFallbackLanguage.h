//
//  NYPLLocalizedStringFallbackLanguage.h
//  Simplified
//
//  Created by Aferdita Muriqi on 5/25/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#ifndef NYPLLocalizableFallbackLanguage_h
#define NYPLLocalizableFallbackLanguage_h

#define fallbackLanguageBundle [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"]]

#ifdef NSLocalizedString
#undef NSLocalizedString
#endif

#define NSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, fallbackLanguageBundle, comment)


#endif /* NYPLLocalizableFallbackLanguage_h */
