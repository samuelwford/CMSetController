//
//  CMDetailViewController.m
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import "CMDetailViewController.h"
#import <CMSetController.h>

NSString  * const CellIdentifier = @"CellIdentifier";


@interface CMDetailViewController () <CMSetControllerDelegate>
@property (strong, nonatomic) CMSetController *setController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation CMDetailViewController

#pragma mark - Managing the detail item

- (void)setDocument:(CMDocument *)document
{
    if (_document != document) {
        _document = document;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
    if (self.document) {
        
        NSArray *paths = @[@"name", @"favoriteColor"];
        NSArray *sorts = @[[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        
        _setController = [[CMSetController alloc] initWithObserved:self.document
                                                        setKeyPath:@"friends"
                                                          keyPaths:paths
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:sorts
                                                          delegate:self];
        
        NSError *error;
        if (![_setController performQuery:&error]) {
            NSLog(@"oops - %@", error);
            abort();
        }
        
        [self.tableView reloadData];
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Query Delegate

- (void)controllerWillChangeContent:(CMSetController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(CMSetController *)controller didChangeSection:(id<CMSetControllerSectionInfo>)sectionInfo atIndex:(NSUInteger)index forChangeType:(CMSetControllerChangeType)type
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
    
    if (type == CMSetControllerChangeInsert)
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    else
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)controller:(CMSetController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(CMSetControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case CMSetControllerChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case CMSetControllerChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case CMSetControllerChangeUpdate:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell atIndexPath:indexPath];
            break;
        }
            
        case CMSetControllerChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(CMSetController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Table view

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    CMFriend *friend = [[[[_setController sections] objectAtIndex:indexPath.section] objects] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = friend.name;
    cell.detailTextLabel.text = friend.favoriteColor;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_setController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[_setController sections] objectAtIndex:section] name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[_setController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSArray *names;
    static NSArray *colors;
    
    if (!names) {
        names = @[@"john", @"sue", @"bill", @"tom", @"shye", @"evie", @"sam", @"adam"];
    }
    
    if (!colors) {
        colors = @[@"red", @"orange", @"yellow", @"green", @"blue", @"indigo", @"violet"];
    }
    
    CMFriend *friend = [[[[_setController sections] objectAtIndex:indexPath.section] objects] objectAtIndex:indexPath.row];
    
    friend.name = [names objectAtIndex:(arc4random() % names.count)];
    friend.favoriteColor = [colors objectAtIndex:(arc4random() % colors.count)];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
