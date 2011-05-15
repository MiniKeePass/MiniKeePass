//
//  SearchViewController.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/15/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "SearchViewController.h"
#import "MobileKeePassAppDelegate.h"
#import "EntryViewController.h"

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Search";
    
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
    
    tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 320, 343) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    
    disableViewOverlay = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 44.0f, 320.0f, 416.0f)];
    disableViewOverlay.backgroundColor = [UIColor blackColor];
    disableViewOverlay.alpha = 0;
    [self.view addSubview:disableViewOverlay];
    
    results = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
    if (indexPath != nil){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)dealloc {
    [tableView release];
    [searchBar release];
    [disableViewOverlay release];
    [results release];
    [super dealloc];
}

- (void)clearResults {
    // Clear the search text
    searchBar.text = @"";
    
    // Delete all the rows
    [results removeAllObjects];
    
    // Pop off any entry views
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    // Reload the table
    [tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)control {
    [self setSearchBar:control active:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)control {
    // Clear the search text
    control.text = @"";
    
    // Deactivate the UISearchBar
    [self setSearchBar:control active:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)control {
    [results removeAllObjects];
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    DatabaseDocument *databaseDocument = appDelegate.databaseDocument;
    
    if (databaseDocument != nil) {
        id<KdbGroup> root = [databaseDocument.kdbTree getRoot];

        // Perform the search
        [databaseDocument searchGroup:root searchText:control.text results:results];
    }
	
    // Deactivate the UISearchBar
    [self setSearchBar:control active:NO];
	
    // Update the table
    [tableView reloadData];
}

- (void)setSearchBar:(UISearchBar*)control active:(BOOL)active {
    tableView.allowsSelection = !active;
    tableView.scrollEnabled = !active;
    
    if (!active) {
        [disableViewOverlay removeFromSuperview];
        [control resignFirstResponder];
    } else {
        disableViewOverlay.alpha = 0;
        [self.view addSubview:disableViewOverlay];
		
        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        disableViewOverlay.alpha = 0.6;
        [UIView commitAnimations];
    }
    
    [control setShowsCancelButton:active animated:YES];
}

- (NSInteger)tableView:(UITableView*)control numberOfRowsInSection:(NSInteger)section {
    return [results count];
}

- (UITableViewCell*)tableView:(UITableView*)control cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [control dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Configure the cell.
    id<KdbEntry> e = [results objectAtIndex:indexPath.row];
    cell.textLabel.text = [e getEntryName];
    cell.imageView.image = [appDelegate loadImage:[e getImage]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<KdbEntry> e = [results objectAtIndex:indexPath.row];
    
    EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    entryViewController.entry = e;
    entryViewController.title = [e getEntryName];
    [self.navigationController pushViewController:entryViewController animated:YES];
    [entryViewController release];
}

@end
