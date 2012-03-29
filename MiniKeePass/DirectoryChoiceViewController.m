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

#import "DirectoryChoiceViewController.h"
#import "MiniKeePassAppDelegate.h"

@implementation DirectoryChoiceViewController

@synthesize path;

- (id)initWithPath:(NSString*)directoryPath {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.path = directoryPath;
        directories = [[NSArray alloc] init];
        NSURL *fileUrl = [NSURL fileURLWithPath:path];
        self.title = fileUrl.lastPathComponent;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];

        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
        [restClient loadMetadata:path];
        
        buttonCell = [[ButtonCell alloc] initWithLabel:@"Sync Current Directory"];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.tableView addGestureRecognizer:longPressGestureRecognizer];
        [longPressGestureRecognizer release];
    }
    
    return self;
}

- (void)dealloc {
    [restClient release];
    [buttonCell release];
    [super dealloc];
}

- (void)cancel {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)handleLongPress:(UIGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:[sender locationInView:self.tableView]];
        if (indexPath != nil) {
            DBMetadata *directory = [directories objectAtIndex:indexPath.row];
            [[NSUserDefaults standardUserDefaults] setValue:directory.path forKey:@"dropboxDirectory"];
            [self.navigationController dismissModalViewControllerAnimated:YES];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : [directories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return buttonCell;
    } else {
        static NSString *CellIdentifier = @"Directory Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        DBMetadata *directory = [directories objectAtIndex:indexPath.row];
        cell.textLabel.text = directory.filename;
        
        return cell;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"dropboxDirectory"];
        [self.navigationController dismissModalViewControllerAnimated:YES];
    } else {    
        DBMetadata *directory = [directories objectAtIndex:indexPath.row];
        
        DirectoryChoiceViewController *directoryChoiceView = [[DirectoryChoiceViewController alloc] initWithPath:directory.path];
        [self.navigationController pushViewController:directoryChoiceView animated:YES];
        [directoryChoiceView release];
    }
}

#pragma mark - DBRestClient delegate
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (DBMetadata *file in metadata.contents) {
        if ([file isDirectory]) {
            [array addObject:file];
        }
    }
    
    [directories release];
    directories = array;
        
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

@end
