//
//  CMDetailViewController.h
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMDocument.h"

@interface CMDetailViewController : UITableViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) CMDocument *document;

@end
