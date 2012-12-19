/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "GroupViewController.h"
#import "EntryViewController.h"
#import "ChooseGroupViewController.h"
#import "AppSettings.h"
#import "RenameItemViewController.h"
#import "Kdb4Node.h"

#define GROUPS_SECTION  0
#define ENTRIES_SECTION 1

#define SORTED_INSERTION_FAILED NSUIntegerMax

@interface GroupViewController ()
- (void)updateLocalArrays;
- (NSUInteger)addObject:object toArray:array;
- (NSUInteger)updatePositionOfObjectAtIndex:(NSUInteger)index inArray:(NSMutableArray *)array;
- (NSUInteger)updatePositionOfObject:object inArray:array;

@property (nonatomic, assign) BOOL selectMultipleWhileEditing;
@property (nonatomic, retain) NSArray *standardToolbarItems;

@property (nonatomic, retain) UIBarButtonItem *deleteButton;
@property (nonatomic, copy) NSString *deleteButtonTitle;
@property (nonatomic, retain) UIBarButtonItem *moveButton;
@property (nonatomic, copy) NSString *moveButtonTitle;
@property (nonatomic, retain) UIBarButtonItem *renameButton;
@property (nonatomic, copy) NSString *renameButtonTitle;

@end

@implementation GroupViewController

- (void)viewDidLoad {
    appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    if ([self.tableView respondsToSelector:@selector(setAllowsMultipleSelectionDuringEditing:)]) {
        self.selectMultipleWhileEditing = YES;
    } else {
        self.selectMultipleWhileEditing = NO;
    }
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBar.placeholder = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Search", nil), self.title];
    
    self.tableView.tableHeaderView = searchBar;
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.delegate = self;
    
    [searchBar release];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStylePlain target:appDelegate action:@selector(showSettingsView)];
    settingsButton.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportFilePressed)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.standardToolbarItems = @[settingsButton, spacer, actionButton, spacer, addButton];
    self.toolbarItems = self.standardToolbarItems;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [settingsButton release];
    [actionButton release];
    [addButton release];
    [spacer release];
    
    results = [[NSMutableArray alloc] init];
    
    groupComparator = ^(id obj1, id obj2) {
        NSString *string1 = ((KdbGroup*)obj1).name;
        NSString *string2 = ((KdbGroup*)obj2).name;
        return [string1 localizedCaseInsensitiveCompare:string2];
    };
    
    entryComparator = ^(id obj1, id obj2) {
        NSString *string1 = ((KdbEntry*)obj1).title;
        NSString *string2 = ((KdbEntry*)obj2).title;
        return [string1 localizedCaseInsensitiveCompare:string2];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if ([selectedIndexPaths count] > 1) {
        [super viewWillAppear:animated];
        return;
    }
    
    NSIndexPath *selectedIndexPath = [selectedIndexPaths objectAtIndex:0];
    
    BOOL sortAlphabetically = [[AppSettings sharedInstance] sortAlphabetically];
    if (sortingEnabled != sortAlphabetically) {
        sortingEnabled = sortAlphabetically;
        selectedIndexPath = nil;
    }

    [self updateLocalArrays];
    [self.tableView reloadData];
    
    // Reload the cell in case the title was changed by the entry view
    if (selectedIndexPath != nil) {
        NSMutableArray *array;
        NSString *newKdbTitle;
        
        switch (selectedIndexPath.section) {
            case ENTRIES_SECTION:
                newKdbTitle = [((KdbEntry *)[enteriesArray objectAtIndex:selectedIndexPath.row]).title copy];
                array = enteriesArray;
                break;
            case GROUPS_SECTION:
                newKdbTitle = [((KdbGroup *)[groupsArray objectAtIndex:selectedIndexPath.row]).name copy];
                array = groupsArray;
                break;
            default:
                @throw [NSException exceptionWithName:@"RuntimeException" reason:@"Invalid Section" userInfo:nil];
                break;
        }

        NSUInteger index = [self updatePositionOfObjectAtIndex:selectedIndexPath.row inArray:array];
            
        // Move or update the row
        if (index != selectedIndexPath.row) {
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:selectedIndexPath.section];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        
        // Re-select the row
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [newKdbTitle release];
    }
    
    searchDisplayController.searchBar.placeholder = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Search", nil), self.title];
    
    [super viewWillAppear:animated];
}

- (void)dealloc {
    [searchDisplayController release];
    [groupsArray release];
    [enteriesArray release];
    [pushedKdbTitle release];
    [results release];
    [group release];
    [_standardToolbarItems release];
    [_deleteButton release];
    [_deleteButtonTitle release];
    [_moveButton release];
    [_moveButtonTitle release];
    [_renameButton release];
    [_renameButtonTitle release];
    [super dealloc];
}

- (void)deleteElementsFromModelAtIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *groupsToRemove = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *enteriesToRemove = [NSMutableArray arrayWithCapacity:10];

    // Find items to remove
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section == GROUPS_SECTION) {
            [groupsToRemove addObject:[groupsArray objectAtIndex:indexPath.row]];
        } else if (indexPath.section == ENTRIES_SECTION) {
            [enteriesToRemove addObject:[enteriesArray objectAtIndex:indexPath.row]];
        }
    }

    // Remove groups
    for (KdbGroup *g in groupsToRemove) {
        [group removeGroup:g];
        [groupsArray removeObject:g];
    }
    
    // Remote Enteries
    for (KdbEntry *e in enteriesToRemove) {
        [group removeEntry:e];
        [enteriesArray removeObject:e];
    }
    
    // Save the database
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    databaseDocument.dirty = YES;
    [databaseDocument save];
}

- (void)deleteSelectedItems {
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
    [self deleteElementsFromModelAtIndexPaths:indexPaths];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Clean up section headers
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    if ([groupsArray count] == 0) {
        [indexSet addIndex:GROUPS_SECTION];
    }
    if ([enteriesArray count] == 0) {
        [indexSet addIndex:ENTRIES_SECTION];
    }
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];

    [self setEditing:NO animated:YES];
}

- (void)moveSelectedItems {
    ChooseGroupViewController *chooseGroupViewController = [[[ChooseGroupViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    chooseGroupViewController.delegate = self;
    UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:chooseGroupViewController] autorelease];
    
    [appDelegate.window.rootViewController presentModalViewController:navController animated:YES];
}

- (BOOL)checkChoiceValidity:(KdbGroup *)chosenGroup success:(void (^)(void))success failure:(void (^)(NSString *))failure {
    BOOL validGroup = YES;
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;
    NSString *errorMessage;
    KdbGroup *movingGroup;
    KdbGroup *movingEntry;
    BOOL containsEntry = NO;
    
    // Check if chosen group is a subgroup of any groups to be moved
    int count = indexPaths.count;
    NSIndexPath *indexPath;
    for (int i = 0; i < count && validGroup; i++) {
        indexPath = [indexPaths objectAtIndex:i];
        switch (indexPath.section) {
            case GROUPS_SECTION:
                movingGroup = [groupsArray objectAtIndex:indexPath.row];
                if (movingGroup.parent == chosenGroup) {
                    validGroup = NO;
                    errorMessage = [NSString stringWithFormat:@"Items are already in %@", chosenGroup.name];
                }
                if ([movingGroup containsGroup:chosenGroup]) {
                    validGroup = NO;
                    errorMessage = [NSString stringWithFormat:@"%@ cannot be moved into %@", movingGroup.name, chosenGroup.name];
                }
                break;
            case ENTRIES_SECTION:
                containsEntry = YES;
                movingEntry = [enteriesArray objectAtIndex:indexPath.row];
                if (movingEntry.parent == chosenGroup) {
                    validGroup = NO;
                    errorMessage = [NSString stringWithFormat:@"Items are already in %@", chosenGroup.name];                    
                }
                break;
        }
    }
    
    // Failed subgroup check
    if (!validGroup) {
        if (failure) {
            failure(errorMessage);
        }
        return NO;
    }
    
    // Check if trying to move entries to top level in 1.x database
    KdbTree *tree = appDelegate.databaseDocument.kdbTree;
    if (![tree isKindOfClass:[Kdb4Tree class]] && tree.root == chosenGroup && containsEntry) {
        if (failure) {
            failure(@"Cannot move entries to top level in 1.x database");
        }
        return NO;
    }
    
    // All tests passsed
    if (success) {
        success();
    }
    return YES;
}

- (void)chooseGroup:(KdbGroup *)chosenGroup {
    NSArray *indexPaths = self.tableView.indexPathsForSelectedRows;

    // Find items to move
    NSMutableArray *groupsToMove = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    NSMutableArray *enteriesToMove = [NSMutableArray arrayWithCapacity:[indexPaths count]];

    for (NSIndexPath *indexPath in indexPaths) {
        switch (indexPath.section) {
            case GROUPS_SECTION:
                [groupsToMove addObject:[groupsArray objectAtIndex:indexPath.row]];
                break;
            case ENTRIES_SECTION:
                [enteriesToMove addObject:[enteriesArray objectAtIndex:indexPath.row]];
                break;
        }
    }

    // Add desired items to chosen group
    for (KdbGroup *movingGroup in groupsToMove) {
        if (movingGroup.parent == chosenGroup) {
            continue;
        }
        [movingGroup.parent moveGroup:movingGroup toGroup:chosenGroup];
        [groupsArray removeObject:movingGroup];
    }
    for (KdbEntry *movingEntry in enteriesToMove) {
        if (movingEntry.parent == chosenGroup) {
            continue;
        }
        [movingEntry.parent moveEntry:movingEntry toGroup:chosenGroup];
        [enteriesArray removeObject:movingEntry];
    }
    
    // Save the database
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    databaseDocument.dirty = YES;
    [databaseDocument save];
    
    // Update the table
    if ([groupsToMove count]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GROUPS_SECTION] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([enteriesToMove count]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ENTRIES_SECTION] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self setEditing:NO animated:YES];
}

- (void)renameSelectedItem {
    [self renameItemAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0]];
}

- (void)setSeachBar:(UISearchBar *)searchBar enabled:(BOOL)enabled {
    static UIView *overlayView = nil;
    if (overlayView == nil) {
        overlayView = [[UIView alloc] initWithFrame:searchBar.frame];
        overlayView.backgroundColor = [UIColor darkGrayColor];
        overlayView.alpha = 0.0;
    }

    searchBar.userInteractionEnabled = enabled;
    if (enabled) {
        [UIView animateWithDuration:0.3 animations:^{
            overlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [overlayView removeFromSuperview];
            [overlayView release];
            overlayView = nil;
        }];
    } else {
        [searchBar addSubview:overlayView];
        [UIView animateWithDuration:0.3 animations:^{
            overlayView.alpha = 0.25;
        }];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (self.selectMultipleWhileEditing) {
        self.tableView.allowsMultipleSelectionDuringEditing = editing;
    }
    
    [super setEditing:editing animated:animated];
    
    // If any cell is showing the delete confirmation swipe gesture was used, don't configure toolbar
    NSArray *cells = self.tableView.visibleCells;
    for (UITableViewCell *cell in cells) {
        if (cell.showingDeleteConfirmation) {
            return;
        }
    }
    
    if (editing && self.selectMultipleWhileEditing) {
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [self setSeachBar:self.searchDisplayController.searchBar enabled:NO];

        self.deleteButtonTitle = NSLocalizedString(@"Delete", nil);
        self.deleteButton = [[[UIBarButtonItem alloc] initWithTitle:self.deleteButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(deleteSelectedItems)] autorelease];
        self.deleteButton.tintColor = [UIColor colorWithRed:0.8 green:0.15 blue:0.15 alpha:1];
        self.deleteButton.width = 97;
        self.deleteButton.enabled = NO;
        
        self.moveButtonTitle = NSLocalizedString(@"Move", nil);
        self.moveButton = [[[UIBarButtonItem alloc] initWithTitle:self.moveButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedItems)] autorelease];
        self.moveButton.width = 97;
        self.moveButton.enabled = NO;
        
        self.renameButtonTitle = NSLocalizedString(@"Rename", nil);
        self.renameButton = [[[UIBarButtonItem alloc] initWithTitle:self.renameButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(renameSelectedItem)] autorelease];
        self.renameButton.width = 97;
        self.renameButton.enabled = NO;
        
        UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
        
        self.toolbarItems = @[self.deleteButton, spacer, self.moveButton, spacer, self.renameButton];
    } else {
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self setSeachBar:self.searchDisplayController.searchBar enabled:YES];

        self.toolbarItems = self.standardToolbarItems;
    }
}

- (void)updateEditingButtons {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSUInteger numSelectedRows = [selectedRows count];
    if (numSelectedRows != 0) {
        self.deleteButton.title = [self.deleteButtonTitle stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.deleteButton.enabled = YES;
        
        self.moveButton.title = [self.moveButtonTitle stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.moveButton.enabled = YES;
        
        self.renameButton.title = [self.renameButtonTitle stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.renameButton.enabled = numSelectedRows == 1;
    } else {
        self.deleteButton.title = self.deleteButtonTitle;
        self.deleteButton.enabled = NO;
        
        self.moveButton.title = self.moveButtonTitle;
        self.moveButton.enabled = NO;
        
        self.renameButton.title = self.renameButtonTitle;
        self.renameButton.enabled = NO;
    }

}

- (KdbGroup *)group {
    return group;
}

- (void)setGroup:(KdbGroup *)newGroup {
    if (group != newGroup) {
        [group release];
        group = [newGroup retain];
        
        [self updateLocalArrays];
                
        [self.tableView reloadData];
    }
}

- (void)updateLocalArrays {
    [groupsArray release];
    [enteriesArray release];
    
    groupsArray = [[NSMutableArray alloc] initWithArray:group.groups];
    enteriesArray = [[NSMutableArray alloc] initWithArray:group.entries];
    
    if (sortingEnabled) {
        [groupsArray sortUsingComparator:groupComparator];
        [enteriesArray sortUsingComparator:entryComparator];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [results removeAllObjects];
    
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    if (databaseDocument != nil) {
        // Perform the search
        [databaseDocument searchGroup:group searchText:searchString results:results];
    }
    
    // Sort the results
    [results sortUsingComparator:^(id a, id b) {
        return [((KdbEntry*)a).title localizedCompare:((KdbEntry*)b).title];
    }];
    
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    }
    
    switch (section) {
        case GROUPS_SECTION:
            if ([groupsArray count] != 0) {
                return NSLocalizedString(@"Groups", nil);
            }
            break;
            
        case ENTRIES_SECTION:
            if ([enteriesArray count] != 0) {
                return NSLocalizedString(@"Entries", nil);
            }
            break;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [results count];
    } else {
        switch (section) {
            case GROUPS_SECTION:
                return [groupsArray count];
            case ENTRIES_SECTION:
                return [enteriesArray count];
        }
        
        return 0;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing && !self.selectMultipleWhileEditing) {
        if (indexPath.section == GROUPS_SECTION) {
            return indexPath;
        }
    } else {
        return indexPath;
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Configure the cell
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // Handle search results
        KdbEntry *e = [results objectAtIndex:indexPath.row];
        cell.textLabel.text = e.title;
        cell.imageView.image = [appDelegate loadImage:e.image];
    } else {
        // Child group/entry
        if (indexPath.section == GROUPS_SECTION) {
            KdbGroup *g = [groupsArray objectAtIndex:indexPath.row];
            cell.textLabel.text = g.name;
            cell.imageView.image = [appDelegate loadImage:g.image];
        } else if (indexPath.section == ENTRIES_SECTION) {
            KdbEntry *e = [enteriesArray objectAtIndex:indexPath.row];
            cell.textLabel.text = e.title;
            cell.imageView.image = [appDelegate loadImage:e.image];
        }
    }
    
    return cell;
}

- (void)renameItemAtIndexPath:(NSIndexPath *)indexPath {
    RenameItemViewController *renameItemViewController = [[RenameItemViewController alloc] initWithStyle:UITableViewStyleGrouped];
    renameItemViewController.delegate = self;

    KdbGroup *g;
    KdbEntry *e;
    
    switch (indexPath.section) {
        case GROUPS_SECTION:
            renameItemViewController.type = RenameItemTypeGroup;
            g = [groupsArray objectAtIndex:indexPath.row];
            renameItemViewController.nameTextField.text = g.name;
            [renameItemViewController setSelectedImageIndex:g.image];
            break;
        case ENTRIES_SECTION:
            renameItemViewController.type = RenameItemTypeEntry;
            e = [enteriesArray objectAtIndex:indexPath.row];
            renameItemViewController.nameTextField.text = e.title;
            [renameItemViewController setSelectedImageIndex:e.image];
            break;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:renameItemViewController];
    
    [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
    
    [navigationController release];
    [renameItemViewController release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // Handle search results
        KdbEntry *e = [results objectAtIndex:indexPath.row];
        
        EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
        entryViewController.entry = e;
        entryViewController.title = e.title;
        [self.navigationController pushViewController:entryViewController animated:YES];
        [entryViewController release];
    } else {
        if (self.editing == NO) {
            if (indexPath.section == GROUPS_SECTION) {
                KdbGroup *g = [groupsArray objectAtIndex:indexPath.row];
                
                GroupViewController *groupViewController = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
                groupViewController.group = g;
                groupViewController.title = g.name;

                [pushedKdbTitle release];
                pushedKdbTitle = [g.name copy];

                [self.navigationController pushViewController:groupViewController animated:YES];
                [groupViewController release];
            } else if (indexPath.section == ENTRIES_SECTION) {
                KdbEntry *e = [enteriesArray objectAtIndex:indexPath.row];
                
                EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
                entryViewController.entry = e;
                entryViewController.title = e.title;
                
                [pushedKdbTitle release];
                pushedKdbTitle = [e.title copy];

                [self.navigationController pushViewController:entryViewController animated:YES];
                [entryViewController release];
            }
        } else if (indexPath.section == GROUPS_SECTION && !self.selectMultipleWhileEditing) {
            [self renameItemAtIndexPath:indexPath];
        } else if (self.selectMultipleWhileEditing) {
            [self updateEditingButtons];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing && self.selectMultipleWhileEditing) {
        [self updateEditingButtons];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == searchDisplayController.searchResultsTableView) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    [self deleteElementsFromModelAtIndexPaths:@[indexPath]];
    
    NSUInteger rows = 0;
    switch (indexPath.section) {
        case GROUPS_SECTION:
            rows = [groupsArray count];
            break;
        case ENTRIES_SECTION:
            rows = [enteriesArray count];
    }
    
    if (rows == 0) {
        // Reload the section if there are no more rows
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        // Delete the row
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    RenameItemViewController *renameItemViewController = (RenameItemViewController*)controller;
    
    if (button == FormViewControllerButtonOk) {
        NSString *newName = renameItemViewController.nameTextField.text;
        if (newName.length == 0) {
            [controller showErrorMessage:NSLocalizedString(@"New name is invalid", nil)];
            return;
        }
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        KdbGroup *g;
        KdbEntry *e;
        
        switch (indexPath.section) {
            case GROUPS_SECTION:
                // Update the group
                g = [groupsArray objectAtIndex:indexPath.row];
                g.name = newName;
                g.image = renameItemViewController.selectedImageIndex;
                break;

            case ENTRIES_SECTION:
                // Update the entry
                e = [enteriesArray objectAtIndex:indexPath.row];
                e.title = newName;
                e.image = renameItemViewController.selectedImageIndex;
                break;
        }
        
        // Save the document
        appDelegate.databaseDocument.dirty = YES;
        [appDelegate.databaseDocument save];
    }
    
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)exportFilePressed {
    BOOL didShow = [appDelegate.databaseDocument.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view.window.rootViewController.view animated:YES];
    if (!didShow) {
        NSString *prompt = NSLocalizedString(@"There are no applications installed capable of importing KeePass files", nil);
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:prompt delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
        [appDelegate showActionSheet:actionSheet];
        [actionSheet release];
    }
}

- (void)addPressed {
    UIActionSheet *actionSheet;
    if (group.canAddEntries) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Group", nil), NSLocalizedString(@"Entry", nil), nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Group", nil), nil];
    }
    
    actionSheet.delegate = self;
    [appDelegate showActionSheet:actionSheet];
    [actionSheet release];    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    if (buttonIndex == 0) {
        // Create and add a group
        KdbGroup *g = [databaseDocument.kdbTree createGroup:group];
        g.name = NSLocalizedString(@"New Group", nil);
        g.image = group.image;
        [group addGroup:g];
        NSUInteger index = [self addObject:g toArray:groupsArray];
        
        databaseDocument.dirty = YES;
        [databaseDocument save];

        EditGroupViewController *editGroupViewController = [[EditGroupViewController alloc] initWithStyle:UITableViewStyleGrouped];
        editGroupViewController.delegate = self;
        editGroupViewController.nameTextField.text = g.name;
        [editGroupViewController setSelectedImageIndex:g.image];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editGroupViewController];
        
        [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
        
        [navigationController release];
        [editGroupViewController release];
        
        // Notify the table of the new row
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:GROUPS_SECTION];
        if ([groupsArray count] == 1) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:GROUPS_SECTION];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        // Select the row
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    } else if (buttonIndex == 1) {
        // Create and add an entry
        KdbEntry *e = [databaseDocument.kdbTree createEntry:group];
        e.title = NSLocalizedString(@"New Entry", nil);
        e.image = group.image;
        [group addEntry:e];
        NSUInteger index = [self addObject:e toArray:enteriesArray];
        databaseDocument.dirty = YES;
        [databaseDocument save];
        
        EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
        entryViewController.entry = e;
        entryViewController.title = e.title;
        entryViewController.isNewEntry = YES;
        [self.navigationController pushViewController:entryViewController animated:YES];
        [entryViewController release];
        
        // Notify the table of the new row
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:ENTRIES_SECTION];
        if ([enteriesArray count] == 1) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:ENTRIES_SECTION];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        // Select the row
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

- (NSUInteger)addObject:object toArray:array {
    NSUInteger index;
    if (sortingEnabled) {
        NSComparisonResult (^comparator) (id obj1, id obj2);
        if ([object isKindOfClass:[KdbGroup class]]) {
            // Object is a KdbGroup, use groupComparator
            comparator = groupComparator;
            
        } else if ([object isKindOfClass:[KdbEntry class]]) {
            // Object is a KdbEntry, use entryComparator
            comparator = entryComparator;
            
        } else {
            // This should be an error some how
            return SORTED_INSERTION_FAILED;
        }
        
        index = [array indexOfObject:object inSortedRange:NSMakeRange(0, [array count]) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
    } else {
        index = [array count];
    }
    
    [array insertObject:object atIndex:index];
    return index;
}

- (NSUInteger)updatePositionOfObjectAtIndex:(NSUInteger)index inArray:(NSMutableArray *)array {
    if (!sortingEnabled) {
        return index;
    }
    
    id object = [[array objectAtIndex:index] retain];
    [array removeObjectAtIndex:index];
    
    NSUInteger newIndex = [self addObject:object toArray:array];    
    
    if (newIndex == SORTED_INSERTION_FAILED) {
        newIndex = index;
        [array insertObject:object atIndex:index];
    }
    
    [object release];    
    return newIndex;
}

- (NSUInteger)updatePositionOfObject:object inArray:array {
    return [self updatePositionOfObjectAtIndex:[array indexOfObject:object] inArray:array];
}

@end
