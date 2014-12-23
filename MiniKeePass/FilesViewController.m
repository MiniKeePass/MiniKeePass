/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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
#import "HelpViewController.h"
#import "DatabaseManager.h"
#import "NewKdbViewController.h"
#import "AppSettings.h"
#import "KeychainUtils.h"
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
    appDelegate = [MiniKeePassAppDelegate appDelegate];

    self.title = NSLocalizedString(@"Files", nil);
    self.tableView.allowsSelectionDuringEditing = YES;

    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:appDelegate
                                                                      action:@selector(showSettingsView)];

    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"help"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(helpPressed)];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addPressed)];

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];

    self.toolbarItems = [NSArray arrayWithObjects:settingsButton, spacer, helpButton, spacer, addButton, nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)displayInfoPage {
    if (filesInfoView == nil) {
        filesInfoView = [[FilesInfoView alloc] initWithFrame:self.view.bounds];
        filesInfoView.viewController = self;
    }

    [self.view addSubview:filesInfoView];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideInfoPage {
    if (filesInfoView != nil) {
        [filesInfoView removeFromSuperview];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Adjust the frame of the filesInfoView to make sure it fills the screen
    filesInfoView.frame = self.view.bounds;
}

- (void)updateFiles {
    // Get the document's directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // Strip out all the directories
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *file in dirContents) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            [files addObject:file];
        }
    }

    // Sort the list of files
    [files sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // Filter the list of files into everything ending with .kdb or .kdbx
    NSArray *databaseFilenames = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH[c] '.kdb') OR (self ENDSWITH[c] '.kdbx')"]];
    
    // Filter the list of files into everything not ending with .kdb or .kdbx
    NSArray *keyFilenames = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!((self ENDSWITH[c] '.kdb') OR (self ENDSWITH[c] '.kdbx'))"]];
    
    databaseFiles = [NSMutableArray arrayWithArray:databaseFilenames];
    keyFiles = [NSMutableArray arrayWithArray:keyFilenames];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DATABASE:
            if ([databaseFiles count] != 0) {
                return NSLocalizedString(@"Databases", nil);
            }
            break;
        case SECTION_KEYFILE:
            if ([keyFiles count] != 0) {
                return NSLocalizedString(@"Key Files", nil);
            }
            break;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger databaseCount = [databaseFiles count];
    NSUInteger keyCount = [keyFiles count];
    
    NSInteger n;
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
        [self displayInfoPage];
    } else {
        [self hideInfoPage];
    }
    
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSString *filename = @"";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell
    switch (indexPath.section) {
        case SECTION_DATABASE:
            filename = [databaseFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = filename;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case SECTION_KEYFILE:
            filename = [keyFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = filename;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        default:
            return nil;
    }

    // Retrieve the Document directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Get the file's modification date
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDate *modificationDate = [[fileManager attributesOfItemAtPath:path error:nil] fileModificationDate];

    // Format the last modified time as the subtitle of the cell
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",
                                 NSLocalizedString(@"Last Modified", nil),
                                 [dateFormatter stringFromDate:modificationDate]];

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
                TextEntryController *textEntryController = [[TextEntryController alloc] init];
                textEntryController.title = NSLocalizedString(@"Rename", nil);
                textEntryController.headerTitle = NSLocalizedString(@"Database Name", nil);
                textEntryController.footerTitle = NSLocalizedString(@"Enter a new name for the password database. The correct file extension will automatically be appended.", nil);
                textEntryController.textField.placeholder = NSLocalizedString(@"Name", nil);
                textEntryController.donePressed = ^(FormViewController *formViewController) {
                    [self renameDatabase:(TextEntryController *)formViewController];
                };
                textEntryController.cancelPressed = ^(FormViewController *formViewController) {
                    [formViewController dismissViewControllerAnimated:YES completion:nil];
                };

                NSString *filename = [databaseFiles objectAtIndex:indexPath.row];
                textEntryController.textField.text = [filename stringByDeletingPathExtension];
                
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:textEntryController];
                
                [appDelegate.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
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
            [KeychainUtils deleteStringForKey:filename andServiceName:@"com.jflan.MiniKeePass.passwords"];
            [KeychainUtils deleteStringForKey:filename andServiceName:@"com.jflan.MiniKeePass.keychains"];
            break;
        case SECTION_KEYFILE:
            filename = [[keyFiles objectAtIndex:indexPath.row] copy];
            [keyFiles removeObject:filename];
            break;
        default:
            return;
    }
    
    // Retrieve the Document directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
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
}

- (void)renameDatabase:(TextEntryController *)textEntryController {
    NSString *newName = textEntryController.textField.text;
    if (newName == nil || [newName isEqualToString:@""]) {
        [textEntryController showErrorMessage:NSLocalizedString(@"Filename is invalid", nil)];
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *oldFilename = [databaseFiles objectAtIndex:indexPath.row];
    NSString *newFilename = [newName stringByAppendingPathExtension:[oldFilename pathExtension]];
    
    // Get the full path of where we're going to move the file
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];

    NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:oldFilename];
    NSString *newPath = [documentsDirectory stringByAppendingPathComponent:newFilename];
    
    // Check if the file already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:newPath]) {
        [textEntryController showErrorMessage:NSLocalizedString(@"A file already exists with this name", nil)];
        return;
    }
    
    // Move input file into documents directory
    [fileManager moveItemAtPath:oldPath toPath:newPath error:nil];
    
    // Update the filename in the files list
    [databaseFiles replaceObjectAtIndex:indexPath.row withObject:newFilename];
    
    // Load the password and keyfile from the keychain under the old filename
    NSString *password = [KeychainUtils stringForKey:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords"];
    NSString *keyFile = [KeychainUtils stringForKey:oldFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles"];
    
    // Store the password and keyfile into the keychain under the new filename
    [KeychainUtils setString:password forKey:newFilename andServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils setString:keyFile forKey:newFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles"];
    
    // Delete the keychain entries for the old filename
    [KeychainUtils deleteStringForKey:oldFilename andServiceName:@"com.jflan.MiniKeePass.passwords"];
    [KeychainUtils deleteStringForKey:oldFilename andServiceName:@"com.jflan.MiniKeePass.keyfiles"];
    
    // Reload the table row
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [textEntryController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addPressed {
    NewKdbViewController *newKdbViewController = [[NewKdbViewController alloc] init];
    newKdbViewController.donePressed = ^(FormViewController *formViewController) {
        [self createNewDatabase:(NewKdbViewController *)formViewController];
    };
    newKdbViewController.cancelPressed = ^(FormViewController *formViewController) {
        [formViewController dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newKdbViewController];
    [appDelegate.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)helpPressed {
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:helpViewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)createNewDatabase:(NewKdbViewController *)newKdbViewController {
    NSString *name = newKdbViewController.nameTextField.text;
    if (name == nil || [name isEqualToString:@""]) {
        [newKdbViewController showErrorMessage:NSLocalizedString(@"Database name is required", nil)];
        return;
    }

    // Check the passwords
    NSString *password1 = newKdbViewController.passwordTextField1.text;
    NSString *password2 = newKdbViewController.passwordTextField2.text;
    if (![password1 isEqualToString:password2]) {
        [newKdbViewController showErrorMessage:NSLocalizedString(@"Passwords do not match", nil)];
        return;
    }
    if (password1 == nil || [password1 isEqualToString:@""]) {
        [newKdbViewController showErrorMessage:NSLocalizedString(@"Password is required", nil)];
        return;
    }

    // Append the correct file extension
    NSString *filename;
    if (newKdbViewController.versionSegmentedControl.selectedSegmentIndex == 0) {
        filename = [name stringByAppendingPathExtension:@"kdb"];
    } else {
        filename = [name stringByAppendingPathExtension:@"kdbx"];
    }

    // Retrieve the Document directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Check if the file already exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        [newKdbViewController showErrorMessage:NSLocalizedString(@"A file already exists with this name", nil)];
        return;
    }

    // Create the KdbWriter for the requested version
    id<KdbWriter> writer;
    if (newKdbViewController.versionSegmentedControl.selectedSegmentIndex == 0) {
        writer = [[Kdb3Writer alloc] init];
    } else {
        writer = [[Kdb4Writer alloc] init];
    }

    // Create the KdbPassword
    KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password1
                                                    passwordEncoding:NSUTF8StringEncoding
                                                             keyFile:nil];

    // Create the new database
    [writer newFile:path withPassword:kdbPassword];

    // Store the password in the keychain
    if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
        [KeychainUtils setString:password1 forKey:filename andServiceName:@"com.jflan.MiniKeePass.passwords"];
    }

    // Add the file to the list of files
    NSUInteger index = [databaseFiles indexOfObject:filename inSortedRange:NSMakeRange(0, [databaseFiles count]) options:NSBinarySearchingInsertionIndex usingComparator:^(id string1, id string2) {
        return [string1 localizedCaseInsensitiveCompare:string2];
    }];
    [databaseFiles insertObject:filename atIndex:index];

    // Notify the table of the new row
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_DATABASE];
    if ([databaseFiles count] == 1) {
        // Reload the section if it's the first item
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SECTION_DATABASE];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationRight];
    } else {
        // Insert the new row
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }

    [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
