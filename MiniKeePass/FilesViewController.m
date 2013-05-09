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
#import "SFHFKeychainUtils.h"
#import "Kdb3Writer.h"
#import "Kdb4Writer.h"
#import "MKPDocumentProvider.h"
#import "LocalDocumentProvider.h"
#import "DropboxDocumentProvider.h"

enum {
    SECTION_DATABASE,
    SECTION_KEYFILE,
    SECTION_NUMBER
};

@interface FilesViewController ()

@property (nonatomic, readonly) MKPDocumentProvider *localDocumentProvider;
@property (nonatomic, readonly) MKPDocumentProvider *dropboxDocumentProvider;
@property (nonatomic, readonly) NSArray *documentProviders;
@property (nonatomic, retain) NSArray *localDatabases;
@property (nonatomic, retain) NSArray *dropboxDatabases;
@property (nonatomic, readonly) NSMutableArray *databases;
@property (nonatomic, retain) NSArray *localKeyFiles;
@property (nonatomic, retain) NSArray *dropboxKeyFiles;
@property (nonatomic, readonly) NSMutableArray *keyFiles;

@end

@implementation FilesViewController

@synthesize selectedFile;

- (void)viewDidLoad {
    appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStylePlain target:appDelegate action:@selector(showSettingsView)];
    settingsButton.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
    
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(helpPressed)];
    helpButton.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:settingsButton, spacer, helpButton, spacer, addButton, nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [settingsButton release];
    [helpButton release];
    [addButton release];
    [spacer release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Files", nil);

        _localDocumentProvider = [[LocalDocumentProvider alloc] init];
        _localDocumentProvider.delegate = self;

        _dropboxDocumentProvider = [[DropboxDocumentProvider alloc] init];
        _dropboxDocumentProvider.delegate = self;

        _documentProviders = [[NSArray alloc] initWithObjects:_localDocumentProvider, _dropboxDocumentProvider, nil];

        _databases = [[NSMutableArray alloc] initWithCapacity:10];
        _keyFiles = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)dealloc {
    [filesInfoView release];
    [_localDocumentProvider release];
    [_dropboxDocumentProvider release];
    [_documentProviders release];
    [_databases release];
    [_keyFiles release];
    [selectedFile release];
    [super dealloc];
}

- (void)displayInfoPage {
    if (filesInfoView == nil) {
        filesInfoView = [[FilesInfoView alloc] initWithFrame:self.view.frame];
        filesInfoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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

- (void)updateFiles {
    for (MKPDocumentProvider *documentProvider in self.documentProviders) {
        [documentProvider updateFiles];
    }
}

- (void)documentProviderDidFinishUpdate:(MKPDocumentProvider *)documentProvider {
    if ([documentProvider isKindOfClass:[LocalDocumentProvider class]]) {
        self.localDatabases = documentProvider.documents;
        self.localKeyFiles = documentProvider.keyFiles;
    } else if ([documentProvider isKindOfClass:[DropboxDocumentProvider class]]) {
        self.dropboxDatabases = documentProvider.documents;
        self.dropboxKeyFiles = documentProvider.keyFiles;
    } else {
        return;
    }

    [self.databases removeAllObjects];
    [self.databases addObjectsFromArray:self.localDatabases];
    [self.databases addObjectsFromArray:self.dropboxDatabases];

    [self.keyFiles removeAllObjects];
    [self.keyFiles addObjectsFromArray:self.localKeyFiles];
    [self.keyFiles addObjectsFromArray:self.dropboxKeyFiles];

    NSLog(@"%@", self.databases);

    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DATABASE: {
            int count = self.databases.count;
            if (count != 0) {
                return NSLocalizedString(@"Databases", nil);
            }
            break;
        }
        case SECTION_KEYFILE: {
            int count = self.keyFiles.count;
            if (count != 0) {
                return NSLocalizedString(@"Key Files", nil);
            }
            break;
        }
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int databaseCount = self.databases.count;
    int keyCount = self.keyFiles.count;
    
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
        [self displayInfoPage];
    } else {
        [self hideInfoPage];
    }
    
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSDate *modificationDate = nil;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell
    switch (indexPath.section) {
        case SECTION_DATABASE: {
            DatabaseFile *database = [self.databases objectAtIndex:indexPath.row];
            cell.textLabel.text = database.filename;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.accessoryView = [[[UIImageView alloc] initWithImage:database.customImage] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            modificationDate = database.modificationDate;
            break;
        }
        case SECTION_KEYFILE: {
            DatabaseFile *keyfile = [self.keyFiles objectAtIndex:indexPath.row];
            cell.textLabel.text = keyfile.filename;
            cell.textLabel.textColor = [UIColor grayColor];
            cell.accessoryView = [[[UIImageView alloc] initWithImage:keyfile.customImage] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            modificationDate = keyfile.modificationDate;
            break;
        }
        default:
            return nil;
    }

    if (modificationDate != nil) {
        // Format the last modified time as the subtitle of the cell
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",
                                     NSLocalizedString(@"Last Modified", nil),
                                     [dateFormatter stringFromDate:modificationDate]];
        [dateFormatter release];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",
                                     NSLocalizedString(@"Last Modified", nil), NSLocalizedString(@"Unknown", nil)];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        // Database file section
        case SECTION_DATABASE:
            if (self.editing == NO) {
                DatabaseFile *database = [self.databases objectAtIndex:indexPath.row];

                switch (database.type) {
                    case DatabaseTypeLocal: {
                        [self.localDocumentProvider openDocument:database];
                        break;
                    }
                    case DatabaseTypeDropbox: {
                        [self.dropboxDocumentProvider openDocument:database];
                        break;
                    }
                }
            } else {
                TextEntryController *textEntryController = [[TextEntryController alloc] initWithStyle:UITableViewStyleGrouped];
                textEntryController.title = NSLocalizedString(@"Rename", nil);
                textEntryController.headerTitle = NSLocalizedString(@"Database Name", nil);
                textEntryController.footerTitle = NSLocalizedString(@"Enter a new name for the password database. The correct file extension will automatically be appended.", nil);
                textEntryController.textEntryDelegate = self;
                textEntryController.textField.placeholder = NSLocalizedString(@"Name", nil);
                
                DatabaseFile *database = [self.databases objectAtIndex:indexPath.row];
                NSString *filename = database.filename;
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
        case SECTION_DATABASE: {
            DatabaseFile *database = [self.databases objectAtIndex:indexPath.row];
            filename = [database.filename copy];
            switch (database.type) {
                case DatabaseTypeLocal:
                    [self.localDocumentProvider deleteDocument:database];
                    break;
                case DatabaseTypeDropbox:
                    [self.dropboxDocumentProvider deleteDocument:database];
                    break;
            }

            // Delete the keychain entries for the old filename
            [SFHFKeychainUtils deleteItemForUsername:filename andServiceName:@"com.jflan.MiniKeePass.passwords" error:nil];
            [SFHFKeychainUtils deleteItemForUsername:filename andServiceName:@"com.jflan.MiniKeePass.keychains" error:nil];
            break;
        }
        case SECTION_KEYFILE: {
            DatabaseFile *keyFile = [self.keyFiles objectAtIndex:indexPath.row];
            switch (keyFile.type) {
                case DatabaseTypeLocal:
                    [self.localDocumentProvider deleteKeyFile:keyFile];
                    break;
                case DatabaseTypeDropbox:
                    [self.dropboxDocumentProvider deleteKeyFile:keyFile];
                    break;
            }
            break;
        }
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
    if (string.length == 0) {
        [controller showErrorMessage:NSLocalizedString(@"Filename is invalid", nil)];
        return;
    }

    NSError *error;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    DatabaseFile *database = [self.databases objectAtIndex:indexPath.row];
    switch (database.type) {
        case DatabaseTypeLocal:
            error = [self.localDocumentProvider renameDocument:database to:string];
            break;
        case DatabaseTypeDropbox:
            error = [self.dropboxDocumentProvider renameDocument:database to:string];
            break;
    }

    if (error != nil) {
        [controller showErrorMessage:[error.userInfo objectForKey:@"errorMessage"]];
        return;
    }

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

- (void)helpPressed {
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    
    [self.navigationController pushViewController:helpViewController animated:YES];
    
    [helpViewController release];
}

- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button {
    /* FIXME
    if (button == FormViewControllerButtonOk) {
        NewKdbViewController *viewController = (NewKdbViewController*)controller;
        
        NSString *name = viewController.nameTextField.text;
        if (name == nil || [name isEqualToString:@""]) {
            [viewController showErrorMessage:NSLocalizedString(@"Database name is required", nil)];
            return;
        }
        
        // Check the passwords
        NSString *password1 = viewController.passwordTextField1.text;
        NSString *password2 = viewController.passwordTextField2.text;
        if (![password1 isEqualToString:password2]) {
            [viewController showErrorMessage:NSLocalizedString(@"Passwords do not match", nil)];
            return;
        }
        if (password1 == nil || [password1 isEqualToString:@""]) {
            [viewController showErrorMessage:NSLocalizedString(@"Password is required", nil)];
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
            [viewController showErrorMessage:NSLocalizedString(@"A file already exists with this name", nil)];
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
        KdbPassword *kdbPassword = [[KdbPassword alloc] initWithPassword:password1
                                                        passwordEncoding:NSUTF8StringEncoding
                                                                 keyFile:nil];
        
        // Create the new database
        [writer newFile:path withPassword:kdbPassword];
        [writer release];
        
        [kdbPassword release];
        
        // Store the password in the keychain
        if ([[AppSettings sharedInstance] rememberPasswordsEnabled]) {
            NSError *error;
            [SFHFKeychainUtils storeUsername:filename andPassword:password1 forServiceName:@"com.jflan.MiniKeePass.passwords" updateExisting:YES error:&error];
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
    }
     */

    [appDelegate.window.rootViewController dismissModalViewControllerAnimated:YES];
}

@end
