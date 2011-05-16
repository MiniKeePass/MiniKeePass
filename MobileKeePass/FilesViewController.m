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

#import "FilesViewController.h"
#import "MobileKeePassAppDelegate.h"
#import "DatabaseManager.h"

@implementation FilesViewController

@synthesize selectedFile;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Files";
    }
    return self;
}

- (void)dealloc {
    [openHelpView release];
    [files release];
    [selectedFile release];
    [super dealloc];
}

- (void)displayHelpPage {
    if (openHelpView == nil) {
        openHelpView = [[OpenHelpView alloc] initWithFrame:self.view.frame];
        openHelpView.navigationController = self.navigationController;
    }
    
    [self.view addSubview:openHelpView];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideHelpPage {
    if (openHelpView != nil) {
        [openHelpView removeFromSuperview];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.scrollEnabled = YES;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [files release];
    
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSArray *filenames = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH '.kdb') OR (self ENDSWITH '.kdbx')"]];
    files = [[NSMutableArray arrayWithArray:filenames] retain];
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int n = [files count];
    
    // Show the help view if there are no files
    if (n == 0) {
        [self displayHelpPage];
    } else {
        [self hideHelpPage];
    }
    
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell
    cell.textLabel.text = [files objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get the Documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Add the filename to the documents directory
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[files objectAtIndex:indexPath.row]];

    // Load the database
    [[DatabaseManager sharedInstance] openDatabaseDocument:path animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filename = [files objectAtIndex:indexPath.row];

        // Retrieve the Document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
        
        // Get the application delegate
        MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        // Close the current database if we're deleting it's file
        if ([path isEqualToString:appDelegate.databaseDocument.filename]) {
            [appDelegate closeDatabase];
        }
        
        // Delete the file
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:path error:nil];
        [fileManager release];
        
        // Remove the file from the array
        [files removeObject:filename];
        
        // Update the table
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
