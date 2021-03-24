// Global function to label strings that do not need to be localized
// so as to not set off Analyzer localization warnings
__attribute__((annotate("returns_localized_nsstring")))
NSString *NYPLLocalizationNotNeeded(NSString *s);
