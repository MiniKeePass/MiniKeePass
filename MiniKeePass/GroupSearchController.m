/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
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
