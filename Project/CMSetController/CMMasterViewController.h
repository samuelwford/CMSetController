//
//  CMMasterViewController.h
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CMDetailViewController;

@interface CMMasterViewController : UITableViewController

@property (strong, nonatomic) CMDetailViewController *detailViewController;

@end
