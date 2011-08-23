/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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
#import "EditGroupViewController.h"

#define GROUPS_SECTION  0
#define ENTRIES_SECTION 1

@implementation GroupViewController

- (void)viewDidLoad {
    appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBar.placeholder = [NSString stringWithFormat:@"Search %@", self.title];
    
    self.tableView.tableHeaderView = searchBar;
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.delegate = self;
    
    [searchBar release];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tab_gear"] style:UIBarButtonItemStylePlain target:appDelegate action:@selector(showSettingsView)];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportFilePressed)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:settingsButton, spacer, actionButton, spacer, addButton, nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [settingsButton release];
    [actionButton release];
    [addButton release];
    [spacer release];
    
    results = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    // Reload the cell in case the title was changed by the entry view
    if (selectedIndexPath != nil) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    searchDisplayController.searchBar.placeholder = [NSString stringWithFormat:@"Search %@", self.title];
    
    CGFloat searchBarHeight = searchDisplayController.searchBar.frame.size.height;
    if (self.tableView.contentOffset.y < searchBarHeight) {
        self.tableView.contentOffset = CGPointMake(0, searchBarHeight);
    }
    
    [super viewWillAppear:animated];
}

- (void)dealloc {
    [searchDisplayController release];
    [results release];
    [group release];
    [super dealloc];
}

- (KdbGroup *)group {
    return group;
}

- (void)setGroup:(KdbGroup *)newGroup {
    group = [newGroup retain];
    [self.tableView reloadData];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [results removeAllObjects];
    
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    if (databaseDocument != nil) {
        // Perform the search
        [databaseDocument searchGroup:group searchText:searchString results:results];
    }
    
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
            if ([group.groups count] != 0) {
                return @"Groups";
            }
            break;
            
        case ENTRIES_SECTION:
            if ([group.entries count] != 0) {
                return @"Entries";
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
                return [group.groups count];
            case ENTRIES_SECTION:
                return [group.entries count];
        }
        
        return 0;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
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
            KdbGroup *g = [group.groups objectAtIndex:indexPath.row];
            cell.textLabel.text = g.name;
            cell.imageView.image = [appDelegate loadImage:g.image];
        } else if (indexPath.section == ENTRIES_SECTION) {
            KdbEntry *e = [group.entries objectAtIndex:indexPath.row];
            cell.textLabel.text = e.title;
            cell.imageView.image = [appDelegate loadImage:e.image];
        }
    }
    
    return cell;
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
                KdbGroup *g = [group.groups objectAtIndex:indexPath.row];
                
                GroupViewController *groupViewController = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
                groupViewController.group = g;
                groupViewController.title = g.name;
                [self.navigationController pushViewController:groupViewController animated:YES];
                [groupViewController release];
            } else if (indexPath.section == ENTRIES_SECTION) {
                KdbEntry *e = [group.entries objectAtIndex:indexPath.row];
                
                EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
                entryViewController.entry = e;
                entryViewController.title = e.title;
                [self.navigationController pushViewController:entryViewController animated:YES];
                [entryViewController release];
            }
        } else if (indexPath.section == GROUPS_SECTION) {
            KdbGroup *g = [group.groups objectAtIndex:indexPath.row];
            
            EditGroupViewController *editGroupViewController = [[EditGroupViewController alloc] initWithStyle:UITableViewStyleGrouped];
            editGroupViewController.delegate = self;
            editGroupViewController.nameTextField.text = g.name;
            [editGroupViewController setSelectedImageIndex:g.image];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editGroupViewController];
            
            [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
            
            [navigationController release];
            [editGroupViewController release];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    // Update the model
    NSUInteger rows = 0;
    if (indexPath.section == GROUPS_SECTION) {
        KdbGroup *g = [group.groups objectAtIndex:indexPath.row];
        [group removeGroup:g];
        rows = [group.groups count];
    } else if (indexPath.section == ENTRIES_SECTION) {
        KdbEntry *e = [group.entries objectAtIndex:indexPath.row];
        [group removeEntry:e];
        rows = [group.entries count];
    }
    
    // Save the database
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    databaseDocument.dirty = YES;
    [databaseDocument save];

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
    EditGroupViewController *editGroupViewController = (EditGroupViewController*)controller;
    
    if (button == FormViewControllerButtonOk) {
        NSString *groupName = editGroupViewController.nameTextField.text;
        if (groupName == nil || [groupName isEqualToString:@""]) {
            [controller showErrorMessage:@"Group name is invalid"];
            return;
        }
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        // Update the group
        KdbGroup *g = [group.groups objectAtIndex:indexPath.row];
        g.name = groupName;
        g.image = editGroupViewController.selectedImageIndex;
        
        // Save the document
        appDelegate.databaseDocument.dirty = YES;
        [appDelegate.databaseDocument save];
        
        // Reload the table row
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)textEntryControllerCancelButtonPressed:(TextEntryController *)controller {
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)exportFilePressed {
    BOOL didShow = [appDelegate.databaseDocument.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view.window animated:YES];
    if (!didShow) {
        NSString *prompt = @"There are no applications installed capable of importing KeePass files";
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:prompt delegate:nil cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil];
        [appDelegate showActionSheet:actionSheet];
        [actionSheet release];
    }
}

- (void)addPressed {
    UIActionSheet *actionSheet;
    if (group.canAddEntries) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Group", @"Entry", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Group", nil];
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
        g.name = @"New Group";
        g.image = group.image;
        [group addGroup:g];
        
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
        NSUInteger index = [group.groups count] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:GROUPS_SECTION];
        if (index == 0) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:GROUPS_SECTION];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
        
        // Select the row
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    } else if (buttonIndex == 1) {
        // Create and add an entry
        KdbEntry *e = [databaseDocument.kdbTree createEntry:group];
        e.title = @"New Entry";
        e.image = group.image;
        [group addEntry:e];
        
        databaseDocument.dirty = YES;
        [databaseDocument save];
        
        EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
        entryViewController.entry = e;
        entryViewController.title = e.title;
        entryViewController.isNewEntry = YES;
        [self.navigationController pushViewController:entryViewController animated:YES];
        [entryViewController release];
        
        // Notify the table of the new row
        NSUInteger index = [group.entries count] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:ENTRIES_SECTION];
        if (index == 0) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:ENTRIES_SECTION];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationLeft];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
        
        // Select the row
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

@end
