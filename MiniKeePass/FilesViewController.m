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
#import "SFHFKeychainUtils.h"
#import "Kdb3Writer.h"
#import "Kdb4Writer.h"

enum {
    SECTION_DATABASE,
    SECTION_KEYFILE,
    SECTION_NUMBER
};

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
    [databaseFiles release];
    [keyFiles release];
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
    [self updateFiles];
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    [self.tableView reloadData];

    if (selectedIndexPath != nil) {
        [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    [super viewWillAppear:animated];
}

- (void)updateFiles {
    [databaseFiles release];
    [keyFiles release];
    
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Get the list of files in the documents directory
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSArray *databaseFilenames = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH '.kdb') OR (self ENDSWITH '.kdbx')"]];
    NSArray *keyFilenames = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!((self ENDSWITH '.kdb') OR (self ENDSWITH '.kdbx'))"]];
    
    databaseFiles = [[NSMutableArray arrayWithArray:databaseFilenames] retain];
    keyFiles = [[NSMutableArray arrayWithArray:keyFilenames] retain];    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DATABASE:
            if ([databaseFiles count] != 0) {
                return @"Databases";
            }
            break;
        case SECTION_KEYFILE:
            if ([keyFiles count] != 0) {
                return @"Key Files";
            }
            break;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int databaseCount = [databaseFiles count];
    int keyCount = [keyFiles count];
    
    int n;
    switch (section) {
        case SECTION_DATABASE:
            n = databaseCount;
            break;
        case SECTION_KEYFILE:
            n = keyCount;
            break;
        default:
            n = 0;
            break;
    }
    
    // Show the help view if there are no files
    if (databaseCount == 0 && keyCount == 0) {
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
    switch (indexPath.section) {
        case SECTION_DATABASE:
            cell.textLabel.text = [databaseFiles objectAtIndex:indexPath.row];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case SECTION_KEYFILE:
            cell.textLabel.text = [keyFiles objectAtIndex:indexPath.row];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        // Database file section
        case SECTION_DATABASE:
            if (self.editing == NO) {
                // Load the database
                [[DatabaseManager sharedInstance] openDatabaseDocument:[databaseFiles objectAtIndex:indexPath.row] animated:YES];
            } else {
                TextEntryController *textEntryController = [[TextEntryController alloc] initWithStyle:UITableViewStyleGrouped];
                textEntryController.title = @"Rename";
                textEntryController.headerTitle = @"Database Name";
                textEntryController.footerTitle = @"Enter a new name for the password database.  The correct file extension will automatically be appended.";
                textEntryController.textEntryDelegate = self;
                textEntryController.textField.placeholder = @"Name";
                
                NSString *filename = [databaseFiles objectAtIndex:indexPath.row];
                textEntryController.textField.text = [filename stringByDeletingPathExtension];
                
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textEntryController];
                
                [appDelegate.window.rootViewController presentModalViewController:navigationController animated:YES];
                
                [navigationController release];
                [textEntryController release];
            }
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }

    NSString *filename;
    switch (indexPath.section) {
        case SECTION_DATABASE:
            filename = [[databaseFiles objectAtIndex:indexPath.row] copy];
            [databaseFiles removeObject:filename];

            // Delete the keychain entries for the old filename
            [SFHFKeychainUtils deleteItemForUsername:filename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
            [SFHFKeychainUtils deleteItemForUsername:filename andServiceName:@"com.jflan.MiniKeePass.keychains" error:nil];
            break;
        case SECTION_KEYFILE:
            filename = [[keyFiles objectAtIndex:indexPath.row] copy];
            [keyFiles removeObject:filename];
            break;
        default:
            return;
    }
    
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
    
    // Update the table
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    
    [filename release];
}

- (void)textEntryController:(TextEntryController *)controller textEntered:(NSString *)string {
    if (string == nil || [string isEqualToString:@""]) {
        [controller showErrorMessage:@"Filename is invalid"];
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *oldFilename = [[databaseFiles objectAtIndex:indexPath.row] retain];
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
        [oldFilename release];
        return;
    }
    
    // Move input file into documents directory
    [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];
    
    // Update the filename in the files list
    [databaseFiles replaceObjectAtIndex:indexPath.row withObject:newFilename];
    
    // Load the password and keyfile from the keychain under the old filename
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    NSString *keyFile = [SFHFKeychainUtils getPasswordForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles" error:nil];
    
    // Store the password and keyfile into the keychain under the new filename
    [SFHFKeychainUtils storeUsername:newFilename andPassword:password forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:nil];
    [SFHFKeychainUtils storeUsername:newFilename andPassword:keyFile forServiceName:@"com.jflan.MiniKeePass.keyfiles" updateExisting:YES error:nil];
    
    // Delete the keychain entries for the old filename
    [SFHFKeychainUtils deleteItemForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
    [SFHFKeychainUtils deleteItemForUsername:oldFilename andServiceName:@"com.jflan.MiniKeePass.keychains" error:nil];
    
    [oldFilename release];
    
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
        
        // Append the correct file extension
        NSString *filename;
        if (viewController.versionSegmentedControl.selectedSegmentIndex == 0) {
             filename = [name stringByAppendingPathExtension:@"kdb"];
        } else {
            filename = [name stringByAppendingPathExtension:@"kdbx"];
        }
        
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
        
        // Create the KdbWriter for the requested version
        id<KdbWriter> writer;
        if (viewController.versionSegmentedControl.selectedSegmentIndex == 0) {
            writer = [[Kdb3Writer alloc] init];
        } else {
            writer = [[Kdb4Writer alloc] init];
        }
        
        // Create the KdbPassword
        KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password1 encoding:NSUTF8StringEncoding];
        
        // Create the new database
        [writer newFile:path withPassword:kdbPassword];
        [writer release];
        
        [kdbPassword release];
        
        // Store the password in the keychain
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults boolForKey:@"rememberPasswordsEnabled"]) {
            NSError *error;
            [SFHFKeychainUtils storeUsername:filename andPassword:password1 forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:&error];
        }
        
        // Add the file to the list of files
        [databaseFiles addObject:filename];
        
        // Notify the table of the new row
        NSUInteger index = [databaseFiles count] - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_DATABASE];
        if (index == 0) {
            // Reload the section if it's the first item
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SECTION_DATABASE];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationRight];
        } else {
            // Insert the new row
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
    
    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

@end
