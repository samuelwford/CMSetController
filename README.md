# CMSetController

`CMSetController` is a KVO controller for NSSet that behaves like an NSFetchedResultController without Core Data.

Given an object with an NSSet property containing objects you want to bind to a table view, provide (very similar to an `NSFetchedResultController`):

* The key path of the set.
* One or more key paths of properties to observe for the objects in the set.
* One or more sort descriptors to order the objects.
* Optionally the key path to a property of the objects to group them by.

The controller will provide a set of sections and objects to populate a `UITableView` datasource. It will also call back a delegate class when changes occur to the objects in the set for update, insertion, removal, reordering, and section changes.

## Usage

Configure the `CMSetController` when configuring the view for the bound item. If you don't have a model object that holds a set, make the set a property of your controller.

```objective-c
// watch for changes to either the "name" or "favoriteColor" properties
NSArray *paths = @[@"name", @"favoriteColor"];

// sort by "favoriteColor" (first sort must match section key path, if any) then "name"
NSArray *sorts = @[[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

// observe the "friends" set property of the "self.document" object using the key paths and
// sorts setup above, group by "favoriteColor" into sections, and receive delegate callbacks
// as the set changes
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
```

Populate the table view just like using an `NSFetchedResultController`:

```objective-c
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
```

If you've implemented the `CMSetControllerDelegate`, you will get callbacks tailored to update the table view:

```objective-c
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
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            
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
```

## Contact

[Samuel Ford](samuel.ford@icloud.com)
[@causticmango](https://twitter.com/causticmango)

## License

CMSetController is released under the MIT license. See LICENSE file for more details.