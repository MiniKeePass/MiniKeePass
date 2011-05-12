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
#import "MobileKeePassAppDelegate.h"

@implementation GroupViewController

- (void)dealloc {
    [group release];
    [super dealloc];
}

- (id<KdbGroup>)group {
    return group;
}

- (void)setGroup:(id<KdbGroup>)newGroup {
    group = [newGroup retain];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (group == nil) {
        return 0;
    }
    
    return [[group getSubGroups] count] + [[group getEntries] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Configure the cell.
    int numChildren = [[group getSubGroups] count];
    if (indexPath.row < numChildren) {
        id<KdbGroup> g = [[group getSubGroups] objectAtIndex:indexPath.row];
        cell.textLabel.text = [g getGroupName];
        cell.imageView.image = [appDelegate loadImage:[g getImage]];
    } else {
        id<KdbEntry> e = [[group getEntries] objectAtIndex:(indexPath.row - numChildren)];
        cell.textLabel.text = [e getEntryName];
        cell.imageView.image = [appDelegate loadImage:[e getImage]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int numChildren = [[group getSubGroups] count];
    if (indexPath.row < numChildren) {
        id<KdbGroup> g = [[[group getSubGroups] objectAtIndex:indexPath.row] retain];
        
        GroupViewController *groupViewController = [[GroupViewController alloc] initWithStyle:UITableViewStylePlain];
        groupViewController.group = g;
        groupViewController.title = [g getGroupName];
        [self.navigationController pushViewController:groupViewController animated:YES];
        [groupViewController release];
        
        [g release];
    } else {
        id<KdbEntry> e = [[[group getEntries] objectAtIndex:(indexPath.row - numChildren)] retain];
        
        EntryViewController *entryViewController = [[EntryViewController alloc] initWithStyle:UITableViewStyleGrouped];
        entryViewController.entry = e;
        entryViewController.title = [e getEntryName];
        [self.navigationController pushViewController:entryViewController animated:YES];
        [entryViewController release];
        
        [e release];
    }
}

@end
