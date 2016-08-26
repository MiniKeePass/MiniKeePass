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
#import "DatabaseManager.h"
#import "AppSettings.h"
#import "KeychainUtils.h"
#import "Kdb3Writer.h"
#import "Kdb4Writer.h"
#import "MiniKeePass-swift.h"

enum {
    SECTION_DATABASE,
    SECTION_KEYFILE,
    SECTION_NUMBER
};

@interface FilesViewController ()
@property (nonatomic, strong) FilesInfoView *filesInfoView;
@property (nonatomic, strong) NSMutableArray *databaseFiles;
@property (nonatomic, strong) NSMutableArray *keyFiles;
@end

@implementation FilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Files", nil);
    self.tableView.allowsSelectionDuringEditing = YES;

    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
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
                                                                               action:@selector(addPressed:)];

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];

    self.toolbarItems = [NSArray arrayWithObjects:settingsButton, spacer, helpButton, spacer, addButton, nil];
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
    self.filesInfoView.frame = self.view.bounds;
}

- (void)updateFiles {
    self.databaseFiles = [[NSMutableArray alloc] init];
    self.keyFiles = [[NSMutableArray alloc] init];

    // Get the document's directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Sort the files into database files and keyfiles
    for (NSString *file in dirContents) {
        NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

        // Check if it's a directory
        BOOL dir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&dir];
        if (!dir) {
            NSString *extension = [[file pathExtension] lowercaseString];
            if ([extension isEqualToString:@"kdb"] || [extension isEqualToString:@"kdbx"]) {
                [self.databaseFiles addObject:file];
            } else {
                [self.keyFiles addObject:file];
            }
        }
    }

    // Sort the list of files
    [self.databaseFiles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.keyFiles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)displayInfoView {
    if (self.filesInfoView == nil) {
        self.filesInfoView = [[FilesInfoView alloc] initWithFrame:self.view.bounds];
        self.filesInfoView.viewController = self;
    }

    [self.view addSubview:self.filesInfoView];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;

    self.navigationItem.rightBarButtonItem = nil;
}

- (void)hideInfoView {
    if (self.filesInfoView != nil) {
        [self.filesInfoView removeFromSuperview];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.scrollEnabled = YES;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DATABASE:
            if ([self.databaseFiles count] != 0) {
                return NSLocalizedString(@"Databases", nil);
            }
            break;
        case SECTION_KEYFILE:
            if ([self.keyFiles count] != 0) {
                return NSLocalizedString(@"Key Files", nil);
            }
            break;
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger databaseCount = [self.databaseFiles count];
    NSUInteger keyCount = [self.keyFiles count];

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
        [self displayInfoView];
    } else {
        [self hideInfoView];
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
            filename = [self.databaseFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = filename;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
        case SECTION_KEYFILE:
            filename = [self.keyFiles objectAtIndex:indexPath.row];
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }

    NSString *filename;
    switch (indexPath.section) {
        case SECTION_DATABASE:
            filename = [[self.databaseFiles objectAtIndex:indexPath.row] copy];
            [self.databaseFiles removeObject:filename];

            // Delete the keychain entries for the old filename
            if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
                [KeychainUtils deleteStringForKey:filename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
                [KeychainUtils deleteStringForKey:filename andServiceName:KEYCHAIN_KEYFILES_SERVICE];
            }
            break;
        case SECTION_KEYFILE:
            filename = [[self.keyFiles objectAtIndex:indexPath.row] copy];
            [self.keyFiles removeObject:filename];
            break;
        default:
            return;
    }

    // Retrieve the Document directory
    NSString *documentsDirectory = [MiniKeePassAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Close the current database if we're deleting it's file
    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        // Database file section
        case SECTION_DATABASE:
            if (self.editing == NO) {
                // Load the database
                [[DatabaseManager sharedInstance] openDatabaseDocument:[self.databaseFiles objectAtIndex:indexPath.row] animated:YES];
            } else {
                // Display the Rename Database view
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"RenameDatabase" bundle:nil];
                UINavigationController *navigationController = [storyboard instantiateInitialViewController];
                
                RenameDatabaseViewController *renameDatabaseViewController = (RenameDatabaseViewController *)navigationController.topViewController;
                renameDatabaseViewController.donePressed = ^(RenameDatabaseViewController *renameDatabaseViewController, NSURL *originalUrl, NSURL *newUrl) {
                    [self renameDatabase:originalUrl newUrl:newUrl];
                    [renameDatabaseViewController dismissViewControllerAnimated:YES completion:nil];
                };
                renameDatabaseViewController.cancelPressed = ^(RenameDatabaseViewController *renameDatabaseViewController) {
                    [renameDatabaseViewController dismissViewControllerAnimated:YES completion:nil];
                };
                
                NSString *filename = [self.databaseFiles objectAtIndex:indexPath.row];
                NSURL *documentsDirectory = [MiniKeePassAppDelegate documentsDirectoryUrl];
                renameDatabaseViewController.originalUrl = [documentsDirectory URLByAppendingPathComponent:filename];
                
                [self presentViewController:navigationController animated:YES completion:nil];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Actions

- (void)renameDatabase:(NSURL *)originalUrl newUrl:(NSURL *)newUrl {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    NSString *oldFilename = originalUrl.lastPathComponent;
    NSString *newFilename = newUrl.lastPathComponent;
    
    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtURL:originalUrl toURL:newUrl error:nil];

    // Update the filename in the files list
    [self.databaseFiles replaceObjectAtIndex:indexPath.row withObject:newFilename];

    // Check if we should move the saved passwords to the new filename
    if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
        // Load the password and keyfile from the keychain under the old filename
        NSString *password = [KeychainUtils stringForKey:oldFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        NSString *keyFile = [KeychainUtils stringForKey:oldFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];

        // Store the password and keyfile into the keychain under the new filename
        [KeychainUtils setString:password forKey:newFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        [KeychainUtils setString:keyFile forKey:newFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];

        // Delete the keychain entries for the old filename
        [KeychainUtils deleteStringForKey:oldFilename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
        [KeychainUtils deleteStringForKey:oldFilename andServiceName:KEYCHAIN_KEYFILES_SERVICE];
    }

    // Reload the table row
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)addPressed:(UIBarButtonItem *)source {
    // Display the new database view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewDatabase" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    NewDatabaseViewController *newDatabaseViewController = (NewDatabaseViewController *)navigationController.topViewController;
    newDatabaseViewController.donePressed = ^(NewDatabaseViewController *newDatabaseViewController, NSURL *url, NSString *password, NSInteger version) {
        [self createNewDatabase:url andPassword:password andVersion:version];
        [newDatabaseViewController dismissViewControllerAnimated:YES completion:nil];
    };
    newDatabaseViewController.cancelPressed = ^(NewDatabaseViewController *newDatabaseViewController) {
        [newDatabaseViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)helpPressed {
    // Display the new database view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Help" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];

    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)createNewDatabase:(NSURL *)url andPassword:(NSString *)password andVersion:(NSInteger)version {
    NSString *filename = url.lastPathComponent;

    // Create the KdbWriter for the requested version
    id<KdbWriter> writer;
    if (version == 1) {
        writer = [[Kdb3Writer alloc] init];
    } else {
        writer = [[Kdb4Writer alloc] init];
    }

    // Create the KdbPassword
    KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                    passwordEncoding:NSUTF8StringEncoding
                                                             keyFile:nil];

    // Create the new database
    [writer newFile:url.path withPassword:kdbPassword];

    // Store the password in the keychain
    if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
        [KeychainUtils setString:password forKey:filename andServiceName:KEYCHAIN_PASSWORDS_SERVICE];
    }

    // Add the file to the list of files
    NSUInteger index = [self.databaseFiles indexOfObject:filename
                                           inSortedRange:NSMakeRange(0, [self.databaseFiles count])
                                                 options:NSBinarySearchingInsertionIndex
                                         usingComparator:^(id string1, id string2) {
                                             return [string1 localizedCaseInsensitiveCompare:string2];
                                         }];
    [self.databaseFiles insertObject:filename atIndex:index];

    // Notify the table of the new row
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:SECTION_DATABASE];
    if ([self.databaseFiles count] == 1) {
        // Reload the section if it's the first item
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SECTION_DATABASE];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationRight];
    } else {
        // Insert the new row
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }
}

@end
