// This class modifies the standard UIViewController so that users can dismiss it by tapping outside
// of a modal. This behavior may violate the HIG, but we simply want to do the same thing Apple does
// in its own App Store when displaying details for a particular item.
//
// Subclasses must call super for |viewDidAppear:| and |viewWillDisappear:|.

@interface NYPLDismissibleViewController : UIViewController

@end
