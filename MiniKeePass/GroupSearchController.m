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
        self.appDelegate = [MiniKeePassAppDelegate appDelegate];
        self.results = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
    KdbEntry *entry = [_results objectAtIndex:indexPath.row];
    return [self.groupViewController tableView:tableView cellForEntry:entry];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KdbEntry *entry = [_results objectAtIndex:indexPath.row];
    [self.groupViewController pushViewControllerForEntry:entry];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self.results removeAllObjects];

    // Perform the search
    [DatabaseDocument searchGroup:self.groupViewController.group
                       searchText:searchString
                          results:self.results];

    // Sort the results
    [self.results sortUsingComparator:^(id a, id b) {
        return [((KdbEntry*)a).title localizedCompare:((KdbEntry*)b).title];
    }];

    return YES;
}

@end
