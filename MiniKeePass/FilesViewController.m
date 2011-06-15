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

#import "MiniKeePassAppDelegate.h"
#import "FilesViewController.h"
#import "DatabaseManager.h"
#import "NewKdbViewController.h"
#import "Kdb3Writer.h"

@implementation FilesViewController

@synthesize selectedFile;

- (void)viewDidLoad {
    appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tab_gear"] style:UIBarButtonItemStylePlain target:appDelegate action:@selector(showSettingsView)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:settingsButton, spacer, addButton, nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [settingsButton release];
    [addButton release];
    [spacer release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Files";
    }
    return self;
}

- (void)dealloc {
    [filesHelpView release];
    [files release];
    [selectedFile release];
    [super dealloc];
}

- (void)displayHelpPage {
    if (filesHelpView == nil) {
        filesHelpView = [[FilesHelpView alloc] initWithFrame:self.view.frame];
        filesHelpView.navigationController = self.navigationController;
    }
    
    [self.view addSubview:filesHelpView];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideHelpPage {
    if (filesHelpView != nil) {
        [filesHelpView removeFromSuperview];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.scrollEnabled = YES;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [files release];
    
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Get the list of files in the documents directory
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSArray *filenames = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH '.kdb') OR (self ENDSWITH '.kdbx')"]];
    files = [[NSMutableArray arrayWithArray:filenames] retain];
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    [self.tableView reloadData];

    if (selectedIndexPath != nil) {
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];        
    }
    
    [super viewWillAppear:animated];
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
    if (self.editing == NO) {
        // Load the database
        [[DatabaseManager sharedInstance] openDatabaseDocument:[files objectAtIndex:indexPath.row] animated:YES];
    } else {
        TextEntryController *textEntryController = [[TextEntryController alloc] initWithStyle:UITableViewStyleGrouped];
        textEntryController.title = @"Filename";
        textEntryController.textEntryDelegate = self;
        textEntryController.textField.placeholder = @"Name";
        
        NSString *filename = [files objectAtIndex:indexPath.row];
        textEntryController.textField.text = [filename stringByDeletingPathExtension];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textEntryController];
        
        [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
        
        [navigationController release];
        [textEntryController release];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    NSString *filename = [files objectAtIndex:indexPath.row];
    
    // Retrieve the Document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Close the current database if we're deleting it's file
    if ([path isEqualToString:appDelegate.databaseDocument.filename]) {
        [appDelegate closeDatabase];
    }
    
    // Delete the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:nil];
    
    // Remove the file from the array
    [files removeObject:filename];
    
    // Update the table
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)textEntryController:(TextEntryController *)controller textEntered:(NSString *)string {
    if (string == nil || [string isEqualToString:@""]) {
        [controller showErrorMessage:@"Filename is invalid"];
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *oldFilename = [files objectAtIndex:indexPath.row];
    NSString *newFilename = [string stringByAppendingPathExtension:[oldFilename pathExtension]];
    
    // Get the full path of where we're going to move the file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:oldFilename];
    NSString *newPath = [documentsDirectory stringByAppendingPathComponent:newFilename];
    
    // Check if the file already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:newPath]) {
        [controller showErrorMessage:@"A file already exists with this name"];
        return;
    }
    
    // Move input file into documents directory
    [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];
    
    // Update the filename in the files list
    [files replaceObjectAtIndex:indexPath.row withObject:newFilename];
    
    // Reload the table row
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)textEntryControllerCancelButtonPressed:(TextEntryController *)controller {
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)addPressed {
    NewKdbViewController *newKdbViewController = [[NewKdbViewController alloc] initWithStyle:UITableViewStyleGrouped];
    newKdbViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newKdbViewController];
    
    [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
    
    [navigationController release];
    [newKdbViewController release];
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    if (button == FormViewControllerButtonOk) {
        NewKdbViewController *viewController = (NewKdbViewController*)controller;
        
        NSString *name = viewController.nameTextField.text;
        if (name == nil || [name isEqualToString:@""]) {
            [viewController showErrorMessage:@"Database name is required"];
            return;
        }
        
        // Check the passwords
        NSString *password1 = viewController.passwordTextField1.text;
        NSString *password2 = viewController.passwordTextField2.text;
        if (![password1 isEqualToString:password2]) {
            [viewController showErrorMessage:@"Passwords do not match"];
            return;
        }
        if (password1 == nil || [password1 isEqualToString:@""]) {
            [viewController showErrorMessage:@"Password is required"];
            return;
        }
        
        NSString *filename = [name stringByAppendingPathExtension:@"kdb"];
        
        // Retrieve the Document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
        
        // Check if the file already exists
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [viewController showErrorMessage:@"A file already exists with this name"];
            return;
        }
        
        // Create the new database
        id<KdbWriter> writer = [[Kdb3Writer alloc] init];
        [writer newFile:path withPassword:password1];
        [writer release];
        
        [files addObject:filename];
        
        NSUInteger index = [files count] - 1;
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
    }
    
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

@end
