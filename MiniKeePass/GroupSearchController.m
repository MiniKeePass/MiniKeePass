//
//  GroupSearchController.m
//  MiniKeePass
//
//  Created by John on 12/23/13.
//  Copyright (c) 2013 Self. All rights reserved.
//

#import "GroupSearchController.h"
#import "MiniKeePassAppDelegate.h"

@interface GroupSearchController ()
@property (nonatomic, weak) MiniKeePassAppDelegate *appDelegate;
@property (nonatomic, strong) NSMutableArray *results;
@end

@implementation GroupSearchController

- (id)init {
    self = [super init];
    if (self) {
        _appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        _results = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    // Configure the cell
    KdbEntry * e = [_results objectAtIndex:indexPath.row];
    cell.textLabel.text = e.title;

    // Detail text is a combination of username and url
    NSString *detailText = @"";
    if (e.username != nil && e.username.length > 0) {
        detailText = e.username;
    }
    if (e.url != nil && e.url.length > 0) {
        if (detailText.length > 0) {
            detailText = [NSString stringWithFormat:@"%@ @ %@", detailText, e.url];
        } else {
            detailText = e.url;
        }
    }
    cell.detailTextLabel.text = detailText;
    cell.imageView.image = [_appDelegate loadImage:e.image];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_groupViewController pushViewControllerForEntry:[_results objectAtIndex:indexPath.row]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [_results removeAllObjects];

    DatabaseDocument *databaseDocument = _appDelegate.databaseDocument;
    if (databaseDocument != nil) {
        // Perform the search
        [databaseDocument searchGroup:_group searchText:searchString results:_results];
    }

    // Sort the results
    [_results sortUsingComparator:^(id a, id b) {
        return [((KdbEntry*)a).title localizedCompare:((KdbEntry*)b).title];
    }];

    return YES;
}

@end
