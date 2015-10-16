//
//  NYPLSendingCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
@class NYPLAnimatingButton;

@interface NYPLSendingCardController : NYPLCardApplicationViewController
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *returnToCatalogButton;
- (IBAction)returnToCatalog:(id)sender;
@end
