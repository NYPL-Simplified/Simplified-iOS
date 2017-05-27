//
//  NYPLLocalizableFallbackLanguage.h
//  Simplified
//
//  Created by Aferdita Muriqi on 5/25/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#ifndef NYPLLocalizableFallbackLanguage_h
#define NYPLLocalizableFallbackLanguage_h


#define fallbackLanguageBundle [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"]]
#define NYPLLocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, fallbackLanguageBundle, comment)

#ifdef NSLocalizedString
#undef NSLocalizedString
#endif

#define NSLocalizedString(key, comment) NYPLLocalizedString(key, comment)


#endif /* NYPLLocalizableFallbackLanguage_h */
