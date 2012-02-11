//
//  DirectoryChoiceViewController.m
//  MiniKeePass
//
//  Created by John Flanagan on 2/1/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "DirectoryChoiceViewController.h"
#import "MiniKeePassAppDelegate.h"

@implementation DirectoryChoiceViewController

@synthesize path;

- (id)initWithSettingsViewController:(SettingsViewController*)settingsView andPath:(NSString*)directoryPath {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.path = directoryPath;
        NSURL *fileUrl = [NSURL fileURLWithPath:path];
        self.title = fileUrl.lastPathComponent;
        settingsViewController = settingsView;
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
        [restClient loadMetadata:path];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.tableView addGestureRecognizer:longPressGestureRecognizer];
        [longPressGestureRecognizer release];
    }
    
    return self;
}

- (void)handleLongPress:(UIGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:[sender locationInView:self.tableView]];
        if (indexPath != nil) {
            NSLog(@"Object at index %d was chosen\n", indexPath.row);
            DBMetadata *directory = [directories objectAtIndex:indexPath.row];
            [[NSUserDefaults standardUserDefaults] setValue:directory.path forKey:@"dropboxDirectory"];
            [self.navigationController popToViewController:settingsViewController animated:YES];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [directories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    DBMetadata *directory = [directories objectAtIndex:indexPath.row];
    cell.textLabel.text = directory.filename;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DBMetadata *directory = [directories objectAtIndex:indexPath.row];
    
    DirectoryChoiceViewController *directoryChoiceView = [[DirectoryChoiceViewController alloc] initWithSettingsViewController:settingsViewController andPath:directory.path];
    [self.navigationController pushViewController:directoryChoiceView animated:YES];
    [directoryChoiceView release];
}

#pragma mark - DBRestClient delegate
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray *array = [NSMutableArray array];
    for (DBMetadata *file in metadata.contents) {
        if ([file isDirectory]) {
            [array addObject:file];
        }
    }
    [directories release];
    directories = [NSArray arrayWithArray:array];
    [directories retain];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
}

@end
