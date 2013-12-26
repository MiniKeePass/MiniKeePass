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
#import "GroupSearchController.h"
#import "EntryViewController.h"
#import "ChooseGroupViewController.h"
#import "AppSettings.h"
#import "RenameItemViewController.h"
#import "Kdb3Node.h"

#define PORTRAIT_BUTTON_WIDTH  ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? 97.0f : 244.0f)
#define LANDSCAPE_BUTTON_WIDTH ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? 186.0f : 330.0f)

#define SORTED_INSERTION_FAILED NSUIntegerMax

enum {
    SECTION_GROUPS,
    SECTION_ENTRIES,
    NUM_SECTIONS
};

@interface GroupViewController ()

@property (nonatomic, strong) NSArray *standardToolbarItems;
@property (nonatomic, strong) NSArray *editingToolbarItems;

@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) UIBarButtonItem *moveButton;
@property (nonatomic, strong) UIBarButtonItem *renameButton;
@property (nonatomic, assign) CGFloat currentButtonWidth;

@property (nonatomic, strong) GroupSearchController *searchController;
@property (nonatomic, strong) UISearchDisplayController *mySearchDisplayController;

@end

@implementation GroupViewController

- (id)initWithGroup:(KdbGroup *)group {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _group = group;

        // Get the app delegate
        appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];

        // Configure the various buttons
        self.toolbarItems = self.standardToolbarItems;
        self.navigationItem.rightBarButtonItem = self.editButtonItem;

        // Configure the table
        self.title = self.group.name;
        self.tableView.allowsSelectionDuringEditing = YES;
        self.tableView.allowsMultipleSelectionDuringEditing = YES;

        // Configure the search bar
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.tableView.tableHeaderView = searchBar;

        self.searchController = [[GroupSearchController alloc] init];
        self.searchController.groupViewController = self;

        self.mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        self.searchDisplayController.searchResultsDataSource = self.searchController;
        self.searchDisplayController.searchResultsDelegate = self.searchController;
        self.searchDisplayController.delegate = self.searchController;

        // Get sort settings, and create the sort comparators
        sortingEnabled = [[AppSettings sharedInstance] sortAlphabetically];

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

        // Update the view model from the group information
        [self updateViewModel];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    // Update the search bar's placeholder
    self.searchDisplayController.searchBar.placeholder = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Search", nil), self.title];

    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if ([selectedIndexPaths count] > 1) {
        [super viewWillAppear:animated];
        return;
    }

    BOOL sortAlphabetically = [[AppSettings sharedInstance] sortAlphabetically];
    if (sortingEnabled != sortAlphabetically) {
        // The sorting option changed, reload the entire dataset
        sortingEnabled = sortAlphabetically;
        [self updateViewModel];
        [self.tableView reloadData];
    } else {
        // Reload the cell in case the title was changed by the entry view
        NSIndexPath *selectedIndexPath = [selectedIndexPaths objectAtIndex:0];
        if (selectedIndexPath != nil) {
            NSMutableArray *array;
            switch (selectedIndexPath.section) {
                case SECTION_GROUPS:
                    array = groupsArray;
                    break;
                case SECTION_ENTRIES:
                    array = entriesArray;
                    break;
                default:
                    @throw [NSException exceptionWithName:@"RuntimeException" reason:@"Invalid Section" userInfo:nil];
                    break;
            }

            // Move the group/entry to it's new index in the array
            NSUInteger index = [self updatePositionOfObjectAtIndex:selectedIndexPath.row inArray:array];

            // The row might have moved or changed contents, just reload the data
            [self.tableView reloadData];

            // Re-select the row (it might have changed)
            selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:selectedIndexPath.section];
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }

    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
        self.currentButtonWidth = PORTRAIT_BUTTON_WIDTH;
    } else {
        self.currentButtonWidth = LANDSCAPE_BUTTON_WIDTH;
    }

    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [appDelegate.databaseDocument.documentInteractionController dismissMenuAnimated:NO];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        self.currentButtonWidth = PORTRAIT_BUTTON_WIDTH;
    } else {
        self.currentButtonWidth = LANDSCAPE_BUTTON_WIDTH;
    }

    self.deleteButton.width = self.currentButtonWidth;
    self.moveButton.width = self.currentButtonWidth;
    self.renameButton.width = self.currentButtonWidth;

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)deleteElementsFromModelAtIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *groupsToRemove = [NSMutableArray array];
    NSMutableArray *enteriesToRemove = [NSMutableArray array];

    // Find items to remove
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section == SECTION_GROUPS) {
            [groupsToRemove addObject:[groupsArray objectAtIndex:indexPath.row]];
        } else if (indexPath.section == SECTION_ENTRIES) {
            [enteriesToRemove addObject:[entriesArray objectAtIndex:indexPath.row]];
        }
    }

    // Remove groups
    for (KdbGroup *g in groupsToRemove) {
        [self.group removeGroup:g];
        [groupsArray removeObject:g];
    }

    // Remote Enteries
    for (KdbEntry *e in enteriesToRemove) {
        [self.group removeEntry:e];
        [entriesArray removeObject:e];
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
        [indexSet addIndex:SECTION_GROUPS];
    }
    if ([entriesArray count] == 0) {
        [indexSet addIndex:SECTION_ENTRIES];
    }
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];

    [self setEditing:NO animated:YES];
}

- (void)moveSelectedItems {
    ChooseGroupViewController *chooseGroupViewController = [[ChooseGroupViewController alloc] initWithStyle:UITableViewStylePlain];
    chooseGroupViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chooseGroupViewController];

    [appDelegate.window.rootViewController presentModalViewController:navController animated:YES];
}

- (BOOL)checkChoiceValidity:(KdbGroup *)chosenGroup {
    BOOL validGroup = YES;
    BOOL containsEntry = NO;

    // Check if chosen group is a subgroup of any groups to be moved
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        switch (indexPath.section) {
            case SECTION_GROUPS: {
                KdbGroup *movingGroup = [groupsArray objectAtIndex:indexPath.row];
                if (movingGroup.parent == chosenGroup) {
                    validGroup = NO;
                }
                if ([movingGroup containsGroup:chosenGroup]) {
                    validGroup = NO;
                }
                break;
            }

            case SECTION_ENTRIES: {
                containsEntry = YES;
                KdbEntry *movingEntry = [entriesArray objectAtIndex:indexPath.row];
                if (movingEntry.parent == chosenGroup) {
                    validGroup = NO;
                }
                break;
            }
        }

        if (!validGroup) {
            break;
        }
    }

    // Failed subgroup check
    if (!validGroup) {
        return NO;
    }

    // Check if trying to move entries to top level in 1.x database
    KdbTree *tree = appDelegate.databaseDocument.kdbTree;
    if (containsEntry && chosenGroup == tree.root && [tree isKindOfClass:[Kdb3Tree class]]) {
        return NO;
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
            case SECTION_GROUPS:
                [groupsToMove addObject:[groupsArray objectAtIndex:indexPath.row]];
                break;
            case SECTION_ENTRIES:
                [enteriesToMove addObject:[entriesArray objectAtIndex:indexPath.row]];
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
        [entriesArray removeObject:movingEntry];
    }

    // Save the database
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    databaseDocument.dirty = YES;
    [databaseDocument save];

    // Update the table
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    [self setEditing:NO animated:YES];
}

- (void)renameSelectedItem {
    [self renameItemAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0]];
}

- (void)setSeachBar:(UISearchBar *)searchBar enabled:(BOOL)enabled {
    static UIView *overlayView = nil;
    if (overlayView == nil) {
        overlayView = [[UIView alloc] initWithFrame:searchBar.frame];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        overlayView.backgroundColor = [UIColor darkGrayColor];
        overlayView.alpha = 0.0;
    }

    searchBar.userInteractionEnabled = enabled;
    if (enabled) {
        [UIView animateWithDuration:0.3 animations:^{
            overlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [overlayView removeFromSuperview];
            overlayView = nil;
        }];
    } else {
        [searchBar addSubview:overlayView];
        [UIView animateWithDuration:0.3 animations:^{
            overlayView.alpha = 0.25;
        }];
    }
}

- (NSArray *)standardToolbarItems {
    if (_standardToolbarItems == nil) {
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:appDelegate
                                                                          action:@selector(showSettingsView)];
        settingsButton.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);

        self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                          target:self
                                                                          action:@selector(exportFilePressed)];

        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addPressed)];

        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:nil
                                                                                action:nil];

        _standardToolbarItems = @[settingsButton, spacer, self.actionButton, spacer, addButton];
    }

    return _standardToolbarItems;
}

- (NSArray *)editingToolbarItems {
    if (_editingToolbarItems == nil) {
        self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil)
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(deleteSelectedItems)];
        self.deleteButton.tintColor = [UIColor colorWithRed:0.8 green:0.15 blue:0.15 alpha:1];
        self.deleteButton.width = self.currentButtonWidth;
        self.deleteButton.enabled = NO;

        self.moveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Move", nil)
                                                           style:UIBarButtonItemStyleBordered
                                                          target:self
                                                          action:@selector(moveSelectedItems)];
        self.moveButton.width = self.currentButtonWidth;
        self.moveButton.enabled = NO;

        self.renameButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Rename", nil)
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(renameSelectedItem)];
        self.renameButton.width = self.currentButtonWidth;
        self.renameButton.enabled = NO;

        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:nil
                                                                                action:nil];

        _editingToolbarItems = @[self.deleteButton, spacer, self.moveButton, spacer, self.renameButton];
    }

    return _editingToolbarItems;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    // If any cell is showing the delete confirmation swipe gesture was used, don't configure toolbar
    NSArray *cells = self.tableView.visibleCells;
    for (UITableViewCell *cell in cells) {
        if (cell.showingDeleteConfirmation) {
            return;
        }
    }

    if (editing) {
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [self setSeachBar:self.searchDisplayController.searchBar enabled:NO];

        self.toolbarItems = self.editingToolbarItems;
        [self updateEditingButtons];
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
        self.deleteButton.title = [NSLocalizedString(@"Delete", nil) stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.deleteButton.enabled = YES;

        self.moveButton.title = [NSLocalizedString(@"Move", nil) stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.moveButton.enabled = YES;

        self.renameButton.title = [NSLocalizedString(@"Rename", nil) stringByAppendingFormat:@" (%u)", numSelectedRows];
        self.renameButton.enabled = numSelectedRows == 1;
    } else {
        self.deleteButton.title = NSLocalizedString(@"Delete", nil);
        self.deleteButton.enabled = NO;

        self.moveButton.title = NSLocalizedString(@"Move", nil);
        self.moveButton.enabled = NO;

        self.renameButton.title = NSLocalizedString(@"Rename", nil);
        self.renameButton.enabled = NO;
    }
}

- (void)updateViewModel {
    groupsArray = [[NSMutableArray alloc] initWithArray:self.group.groups];
    entriesArray = [[NSMutableArray alloc] initWithArray:self.group.entries];

    if (sortingEnabled) {
        [groupsArray sortUsingComparator:groupComparator];
        [entriesArray sortUsingComparator:entryComparator];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_GROUPS:
            if ([groupsArray count] != 0) {
                return NSLocalizedString(@"Groups", nil);
            }
            break;

        case SECTION_ENTRIES:
            if ([entriesArray count] != 0) {
                return NSLocalizedString(@"Entries", nil);
            }
            break;
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_GROUPS:
            return [groupsArray count];
        case SECTION_ENTRIES:
            return [entriesArray count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    // Create either a group or entry cell
    switch (indexPath.section) {
        case SECTION_GROUPS: {
            KdbGroup *g = [groupsArray objectAtIndex:indexPath.row];
            cell = [self tableView:tableView cellForGroup:g];
            break;
        }
        case SECTION_ENTRIES: {
            KdbEntry *e = [entriesArray objectAtIndex:indexPath.row];
            cell = [self tableView:tableView cellForEntry:e];
            break;
        }
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForGroup:(KdbGroup *)g {
    static NSString *CellIdentifier = @"CellGroup";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Configure the cell
    cell.textLabel.text = g.name;
    cell.imageView.image = [appDelegate loadImage:g.image];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForEntry:(KdbEntry *)e {
    static NSString *CellIdentifier = @"CellEntry";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Configure the cell
    cell.textLabel.text = e.title;
    cell.imageView.image = [appDelegate loadImage:e.image];

    // Detail text is a combination of username and url
    NSString *detailText = @"";
    if (e.username.length > 0) {
        detailText = e.username;
    }
    if (e.url.length > 0) {
        if (detailText.length > 0) {
            detailText = [NSString stringWithFormat:@"%@ @ %@", detailText, e.url];
        } else {
            detailText = e.url;
        }
    }
    cell.detailTextLabel.text = detailText;

    return cell;
}

- (void)renameItemAtIndexPath:(NSIndexPath *)indexPath {
    RenameItemViewController *renameItemViewController = [[RenameItemViewController alloc] initWithStyle:UITableViewStyleGrouped];
    renameItemViewController.delegate = self;

    switch (indexPath.section) {
        case SECTION_GROUPS: {
            renameItemViewController.type = RenameItemTypeGroup;
            KdbGroup *g = [groupsArray objectAtIndex:indexPath.row];
            renameItemViewController.nameTextField.text = g.name;
            [renameItemViewController setSelectedImageIndex:g.image];
            break;
        }
        case SECTION_ENTRIES: {
            renameItemViewController.type = RenameItemTypeEntry;
            KdbEntry *e = [entriesArray objectAtIndex:indexPath.row];
            renameItemViewController.nameTextField.text = e.title;
            [renameItemViewController setSelectedImageIndex:e.image];
            break;
        }
    }

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:renameItemViewController];

    [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing == NO) {
        switch (indexPath.section) {
            case SECTION_GROUPS: {
                [self pushViewControllerForGroup:[groupsArray objectAtIndex:indexPath.row]];
                break;
            }
            case SECTION_ENTRIES: {
                [self pushViewControllerForEntry:[entriesArray objectAtIndex:indexPath.row]];
                break;
            }
        }
    } else {
        [self updateEditingButtons];
    }
}

- (void)pushViewControllerForGroup:(KdbGroup *)group {
    GroupViewController *groupViewController = [[GroupViewController alloc] initWithGroup:group];

    [self.navigationController pushViewController:groupViewController animated:YES];
}

- (void)pushViewControllerForEntry:(KdbEntry *)entry {
    EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    entryViewController.entry = entry;
    entryViewController.title = entry.title;

    [self.navigationController pushViewController:entryViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        [self updateEditingButtons];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }

    [self deleteElementsFromModelAtIndexPaths:@[indexPath]];

    NSUInteger rows = 0;
    switch (indexPath.section) {
        case SECTION_GROUPS:
            rows = [groupsArray count];
            break;
        case SECTION_ENTRIES:
            rows = [entriesArray count];
            break;
    }

    if (rows == 0) {
        // Reload the section if there are no more rows
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        // Delete the row
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

        switch (indexPath.section) {
            case SECTION_GROUPS: {
                // Update the group
                KdbGroup *g = [groupsArray objectAtIndex:indexPath.row];
                g.name = newName;
                g.image = renameItemViewController.selectedImageIndex;
                break;
            }

            case SECTION_ENTRIES: {
                // Update the entry
                KdbEntry *e = [entriesArray objectAtIndex:indexPath.row];
                e.title = newName;
                e.image = renameItemViewController.selectedImageIndex;
                break;
            }
        }

        // Save the document
        appDelegate.databaseDocument.dirty = YES;
        [appDelegate.databaseDocument save];
    }

    [renameItemViewController dismissViewControllerAnimated:YES completion:nil];

    [self setEditing:NO animated:YES];
}

- (void)exportFilePressed {
    BOOL didShow = [appDelegate.databaseDocument.documentInteractionController presentOpenInMenuFromBarButtonItem:self.actionButton animated:YES];
    if (!didShow) {
        NSString *prompt = NSLocalizedString(@"There are no applications installed capable of importing KeePass files", nil);
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:prompt delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
        [appDelegate showActionSheet:actionSheet];
    }
}

- (void)addPressed {
    UIActionSheet *actionSheet;
    if (self.group.canAddEntries) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add", nil)
                                                  delegate:nil
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Group", nil), NSLocalizedString(@"Entry", nil), nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add", nil)
                                                  delegate:nil
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Group", nil), nil];
    }

    actionSheet.delegate = self;
    [appDelegate showActionSheet:actionSheet];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    if (buttonIndex == 0) {
        // Create and add a group
        KdbGroup *g = [databaseDocument.kdbTree createGroup:self.group];
        g.name = NSLocalizedString(@"New Group", nil);
        g.image = self.group.image;
        [self.group addGroup:g];
        NSUInteger index = [self addObject:g toArray:groupsArray];

        databaseDocument.dirty = YES;
        [databaseDocument save];

        EditGroupViewController *editGroupViewController = [[EditGroupViewController alloc] initWithStyle:UITableViewStyleGrouped];
        editGroupViewController.delegate = self;
        editGroupViewController.nameTextField.text = g.name;
        [editGroupViewController setSelectedImageIndex:g.image];

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editGroupViewController];

        [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];

        // Notify the table of the new row
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_GROUPS];
        if ([groupsArray count] == 1) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SECTION_GROUPS];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        // Select the row
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    } else if (buttonIndex == 1) {
        // Create and add an entry
        KdbEntry *e = [databaseDocument.kdbTree createEntry:self.group];
        e.title = NSLocalizedString(@"New Entry", nil);
        e.image = self.group.image;
        [self.group addEntry:e];
        NSUInteger index = [self addObject:e toArray:entriesArray];
        databaseDocument.dirty = YES;
        [databaseDocument save];

        EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
        entryViewController.entry = e;
        entryViewController.title = e.title;
        entryViewController.isNewEntry = YES;
        [self.navigationController pushViewController:entryViewController animated:YES];

        // Notify the table of the new row
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_ENTRIES];
        if ([entriesArray count] == 1) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SECTION_ENTRIES];
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

    id object = [array objectAtIndex:index];
    [array removeObjectAtIndex:index];
    
    NSUInteger newIndex = [self addObject:object toArray:array];
    
    if (newIndex == SORTED_INSERTION_FAILED) {
        newIndex = index;
        [array insertObject:object atIndex:index];
    }
    
    return newIndex;
}

@end
