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

#import "EntryViewController.h"
#import "Kdb4Node.h"
#import "AppSettings.h"
#import "ImageFactory.h"
#import "MiniKeePass-Swift.h"

#import <MBProgressHUD/MBProgressHUD.h>

#define SECTION_HEADER_HEIGHT 46.0f

enum {
    SECTION_DEFAULT_FIELDS,
    SECTION_CUSTOM_FIELDS,
    SECTION_COMMENTS,
    NUM_SECTIONS
};

@interface EntryViewController() {
    TextFieldCell *titleCell;
    TextFieldCell *usernameCell;
    TextFieldCell *passwordCell;
    TextFieldCell *urlCell;
    TextViewCell *commentsCell;
    
    KdbEntry *originalEntry;
}

@property (nonatomic) BOOL isKdb4;
@property (nonatomic, readonly) NSMutableArray *editingStringFields;
@property (nonatomic, readonly) NSArray *entryStringFields;
@property (nonatomic, readonly) NSArray *currentStringFields;

@property (nonatomic, readonly) NSArray *filledCells;
@property (nonatomic, readonly) NSArray *defaultCells;

@property (nonatomic, readonly) NSArray *cells;

@end

static NSString *TextFieldCellIdentifier = @"TextFieldCell";

@implementation EntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TextFieldCell" bundle:nil] forCellReuseIdentifier:TextFieldCellIdentifier];
    
    titleCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    titleCell.style = TextFieldCellStyleTitle;
    titleCell.title = NSLocalizedString(@"Title", nil);
    titleCell.delegate = self;
    titleCell.textField.placeholder = NSLocalizedString(@"Title", nil);
    titleCell.textField.enabled = NO;
    titleCell.textField.text = self.entry.title;
    [titleCell.editAccessoryButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setSelectedImageIndex:self.entry.image];
    
    usernameCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    usernameCell.style = TextFieldCellStylePlain;
    usernameCell.title = NSLocalizedString(@"Username", nil);
    usernameCell.delegate = self;
    usernameCell.textField.placeholder = NSLocalizedString(@"Username", nil);
    usernameCell.textField.enabled = NO;
    usernameCell.textField.text = self.entry.username;
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    passwordCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    passwordCell.style = TextFieldCellStylePassword;
    passwordCell.title = NSLocalizedString(@"Password", nil);
    passwordCell.delegate = self;
    passwordCell.textField.placeholder = NSLocalizedString(@"Password", nil);
    passwordCell.textField.enabled = NO;
    passwordCell.textField.text = self.entry.password;
    [passwordCell.accessoryButton addTarget:self action:@selector(showPasswordPressed) forControlEvents:UIControlEventTouchUpInside];
    [passwordCell.editAccessoryButton addTarget:self action:@selector(generatePasswordPressed) forControlEvents:UIControlEventTouchUpInside];
    
    urlCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    urlCell.style = TextFieldCellStyleUrl;
    urlCell.title = NSLocalizedString(@"URL", nil);
    urlCell.delegate = self;
    urlCell.textField.placeholder = NSLocalizedString(@"URL", nil);
    urlCell.textField.enabled = NO;
    urlCell.textField.returnKeyType = UIReturnKeyDone;
    urlCell.textField.text = self.entry.url;
    [urlCell.accessoryButton addTarget:self action:@selector(openUrlPressed) forControlEvents:UIControlEventTouchUpInside];
    
    commentsCell = [[TextViewCell alloc] init];
    commentsCell.textView.editable = NO;
    commentsCell.textView.text = self.entry.notes;
    
    _defaultCells = @[titleCell, usernameCell, passwordCell, urlCell];
    
    _editingStringFields = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Hide the toolbar
    [self.navigationController setToolbarHidden:YES animated:animated];

    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Show the toolbar again
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isNewEntry) {
        [self setEditing:YES animated:NO];
        [titleCell.textField becomeFirstResponder];
//        self.isNewEntry = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // Hide the password HUD if it's visible
    [MBProgressHUD hideHUDForView:self.view animated:NO];

    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(id)sender {
    // Resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (void)setEntry:(KdbEntry *)e {
    _entry = e;
    self.isKdb4 = [self.entry isKindOfClass:[Kdb4Entry class]];

    // Update the fields
    self.title = self.entry.title;
    titleCell.textField.text = self.entry.title;
    [self setSelectedImageIndex:self.entry.image];
    usernameCell.textField.text = self.entry.username;
    passwordCell.textField.text = self.entry.password;
    urlCell.textField.text = self.entry.url;
    commentsCell.textView.text = self.entry.notes;
}

- (NSArray *)cells {
    return self.editing ? self.defaultCells : self.filledCells;
}

- (NSArray *)filledCells {
    NSMutableArray *filledCells = [NSMutableArray arrayWithCapacity:self.defaultCells.count];
    for (TextFieldCell *cell in self.defaultCells) {
        if (cell.textField.text.length > 0) {
            [filledCells addObject:cell];
        }
    }
    return filledCells;
}

- (NSArray *)currentStringFields {
    if (!self.isKdb4) {
        return nil;
    }

    if (self.editing) {
        return self.editingStringFields;
    } else {
        return ((Kdb4Entry *)self.entry).stringFields;
    }
}

- (NSArray *)entryStringFields {
    if (self.isKdb4) {
        Kdb4Entry *entry = (Kdb4Entry *)self.entry;
        return entry.stringFields;
    } else {
        return nil;
    }
}

- (void)cancelPressed {
    if( self.isNewEntry ) {
        if( self.newEntryCanceled ) self.newEntryCanceled(self.entry);
        return;
    }
    [self setEditing:NO animated:YES canceled:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if( editing == NO ) {
        self.isNewEntry = NO;
    }
    [self setEditing:editing animated:animated canceled:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated canceled:(BOOL)canceled {
    [super setEditing:editing animated:animated];

    // Ensure that all updates happen at once
    [self.tableView beginUpdates];

    if (editing == NO) {
        if (canceled) {
            originalEntry = nil;
            [self setEntry:self.entry];
        } else {
            self.entry.title = titleCell.textField.text;
            self.entry.image = self.selectedImageIndex;
            self.entry.username = usernameCell.textField.text;
            self.entry.password = passwordCell.textField.text;
            self.entry.url = urlCell.textField.text;
            self.entry.notes = commentsCell.textView.text;
            self.entry.lastModificationTime = [NSDate date];

            if (self.isKdb4) {
                // Ensure any textfield currently being edited is saved
                NSInteger count = [self.tableView numberOfRowsInSection:SECTION_CUSTOM_FIELDS] - 1;
                for (NSInteger i = 0; i < count; i++) {
                    TextFieldCell *cell = (TextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:SECTION_CUSTOM_FIELDS]];
                    [cell.textField resignFirstResponder];
                }

                Kdb4Entry *kdb4Entry = (Kdb4Entry *)self.entry;
                [kdb4Entry.stringFields removeAllObjects];
                [kdb4Entry.stringFields addObjectsFromArray:self.editingStringFields];
                
            }

            DatabaseDocument *doc = [AppDelegate getDelegate].databaseDocument;
            // Save the database document if entry was changed.
            if ([self.entry hasChanged:originalEntry]) {
                if (originalEntry != nil) {
                    // Add edits to the history
                    [doc.kdbTree createEntryBackup:self.entry backupEntry:originalEntry];
                    originalEntry = nil;
                }
                [doc save];
            }
        }
    } else {
        // Save the original state of the entry to know if changes were made.
        if (!self.isNewEntry) {
            originalEntry = [self.entry deepCopy];
        }
    }

    // Index paths for cells to be added or removed
    NSMutableArray *paths = [NSMutableArray array];

    // Manage default cells
    for (TextFieldCell *cell in self.defaultCells) {
        cell.textField.enabled = editing;

        // Add empty cells to the list of cells that need to be added/deleted when changing between editing
        if (cell.textField.text.length == 0) {
            [paths addObject:[NSIndexPath indexPathForRow:[self.defaultCells indexOfObject:cell] inSection:0]];
        }
    }

    [self.editingStringFields removeAllObjects];
    [self.editingStringFields addObjectsFromArray:[self.entryStringFields copy]];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_CUSTOM_FIELDS] withRowAnimation:UITableViewRowAnimationFade];

    if (editing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;

        commentsCell.textView.editable = YES;

        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        self.navigationItem.leftBarButtonItem = nil;

        commentsCell.textView.editable = NO;

        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    }

    // Commit all updates
    [self.tableView endUpdates];
}

#pragma mark - TextFieldCell delegate

- (void)textFieldCellDidEndEditing:(TextFieldCell *)textFieldCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:textFieldCell];

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            if (textFieldCell.style == TextFieldCellStyleTitle) {
                self.title = textFieldCell.textField.text;
            }
            break;
        }
        case SECTION_CUSTOM_FIELDS: {
            if (indexPath.row < self.editingStringFields.count) {
                StringField *stringField = [self.editingStringFields objectAtIndex:indexPath.row];
                stringField.value = textFieldCell.textField.text;
            }
            break;
        }
        default:
            break;
    }
}

- (void)textFieldCellWillReturn:(TextFieldCell *)textFieldCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:textFieldCell];

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            NSInteger nextIndex = indexPath.row + 1;
            if (nextIndex < [self.defaultCells count]) {
                TextFieldCell *nextCell = [self.defaultCells objectAtIndex:nextIndex];
                [nextCell.textField becomeFirstResponder];
            } else {
                [self setEditing:NO animated:YES];
            }
            break;
        }
        case SECTION_CUSTOM_FIELDS: {
            [textFieldCell.textField resignFirstResponder];
        }
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DEFAULT_FIELDS:
            return nil;
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4) {
                if ([self tableView:tableView numberOfRowsInSection:1] > 0) {
                    return NSLocalizedString(@"Custom Fields", nil);
                } else {
                    return nil;
                }
            } else {
                return nil;
            }
        case SECTION_COMMENTS:
            return NSLocalizedString(@"Comments", nil);
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DEFAULT_FIELDS:
            return [self.cells count];
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4) {
                NSUInteger numCells = self.currentStringFields.count;
                // Additional cell for Add cell
                return self.editing ? numCells + 1 : numCells;
            } else {
                return 0;
            }
        case SECTION_COMMENTS:
            return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *AddFieldCellIdentifier = @"AddFieldCell";

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            return [self.cells objectAtIndex:indexPath.row];
        }
        case SECTION_CUSTOM_FIELDS: {
            if (indexPath.row == self.currentStringFields.count) {
                // Return "Add new..." cell
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AddFieldCellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                  reuseIdentifier:AddFieldCellIdentifier];
                    cell.textLabel.textAlignment = NSTextAlignmentLeft;
                    cell.textLabel.text = NSLocalizedString(@"Add new…", nil);

                    // Add new cell when this cell is tapped
                    [cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(addPressed)]];
                }

                return cell;
            } else {
                TextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
                if (cell == nil) {
                    cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                reuseIdentifier:TextFieldCellIdentifier];
                    cell.delegate = self;
                    cell.textField.returnKeyType = UIReturnKeyDone;
                }

                StringField *stringField = [self.currentStringFields objectAtIndex:indexPath.row];

                cell.style = TextFieldCellStylePlain;
                cell.title = stringField.key;
                cell.textField.text = stringField.value;
                cell.textField.enabled = self.editing;

                return cell;
            }
        }
        case SECTION_COMMENTS: {
            return commentsCell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
            break;
        case SECTION_CUSTOM_FIELDS: {
            switch (editingStyle) {
                case UITableViewCellEditingStyleInsert: {
                    [self addPressed];
                    break;
                }
                case UITableViewCellEditingStyleDelete: {
                    TextFieldCell *cell = (TextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
                    [cell.textField resignFirstResponder];

                    [self.editingStringFields removeObjectAtIndex:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case SECTION_COMMENTS:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)addPressed {
    StringField *stringField = [StringField stringFieldWithKey:@"" andValue:@""];
    
    // Display the Rename Database view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CustomField" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    CustomFieldViewController *customFieldViewController = (CustomFieldViewController *)navigationController.topViewController;
    customFieldViewController.donePressed = ^(CustomFieldViewController *customFieldViewController) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
        [self.editingStringFields addObject:customFieldViewController.stringField];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    customFieldViewController.cancelPressed = ^(CustomFieldViewController *customFieldViewController) {
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    customFieldViewController.stringField = stringField;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

# pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // Special case for top section with no section title
    if (section == 0) {
        return 10.0f;
    }

    return [self tableView:tableView titleForHeaderInSection:section] == nil ? 0.0f : SECTION_HEADER_HEIGHT;;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
        case SECTION_CUSTOM_FIELDS:
            return 40.0f;
        case SECTION_COMMENTS:
            return 228.0f;
    }

    return 40.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
            return UITableViewCellEditingStyleNone;
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4 && self.editing) {
                if (indexPath.row < self.currentStringFields.count) {
                    return UITableViewCellEditingStyleDelete;
                } else {
                    return UITableViewCellEditingStyleInsert;
                }
            }
            return UITableViewCellEditingStyleNone;
        case SECTION_COMMENTS:
            return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == SECTION_CUSTOM_FIELDS;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing && indexPath.section == SECTION_DEFAULT_FIELDS) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        if (indexPath.section != SECTION_CUSTOM_FIELDS) {
            return;
        }

        [self editStringField:indexPath];
    } else {
        [self copyCellContents:indexPath];
    }
}

- (void)copyCellContents:(NSIndexPath *)indexPath {
    self.tableView.allowsSelection = NO;

    TextFieldCell *cell = (TextFieldCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = cell.textField.text;
    
    // Construct label
    UILabel *copiedLabel = [[UILabel alloc] initWithFrame:cell.bounds];
    copiedLabel.text = NSLocalizedString(@"Copied", nil);
    copiedLabel.font = [UIFont boldSystemFontOfSize:18];
    copiedLabel.textAlignment = NSTextAlignmentCenter;

    copiedLabel.textColor = [UIColor whiteColor];
    copiedLabel.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1];

    // Put cell into "Copied" state
    [cell addSubview:copiedLabel];

    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.5 animations:^{
            // Return to normal state
            copiedLabel.alpha = 0;
            [cell setSelected:NO animated:YES];
        } completion:^(BOOL finished) {
            [copiedLabel removeFromSuperview];
            self.tableView.allowsSelection = YES;
        }];
    });
}

#pragma mark - StringField related

- (void)editStringField:(NSIndexPath *)indexPath {
    StringField *stringField = [self.editingStringFields objectAtIndex:indexPath.row];
    
    // Display the custom field editing view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CustomField" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    CustomFieldViewController *customFieldViewController = (CustomFieldViewController *)navigationController.topViewController;
    customFieldViewController.donePressed = ^(CustomFieldViewController *customFieldViewController) {
        //NSIndexPath *indexPath = (NSIndexPath *)indexPAthstringFieldController.object;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    customFieldViewController.cancelPressed = ^(CustomFieldViewController *customFieldViewController) {
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    customFieldViewController.stringField = stringField;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Image Selection

- (void)setSelectedImageIndex:(NSUInteger)index {
    _selectedImageIndex = index;

    UIImage *image = [[ImageFactory sharedInstance] imageForIndex:index];
    [titleCell.accessoryButton setImage:image forState:UIControlStateNormal];
    [titleCell.editAccessoryButton setImage:image forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    if (self.tableView.isEditing) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ImageSelector" bundle:nil];
        ImageSelectorViewController *imageSelectorViewController = [storyboard instantiateInitialViewController];
        imageSelectorViewController.selectedImage = _selectedImageIndex;
        imageSelectorViewController.imageSelected = ^(ImageSelectorViewController *imageSelectorViewController, NSInteger selectedImage) {
            self.selectedImageIndex = selectedImage;
        };
        
        [self.navigationController pushViewController:imageSelectorViewController animated:YES];
    }
}

#pragma mark - Password Display

- (void)showPasswordPressed {
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

	hud.mode = MBProgressHUDModeText;
    hud.detailsLabelText = self.entry.password;
    hud.detailsLabelFont = [UIFont fontWithName:@"Andale Mono" size:24];
	hud.margin = 10.f;
	hud.removeFromSuperViewOnHide = YES;
    [hud addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:hud action:@selector(hide:)]];
}

#pragma mark - Password Generation

- (void)generatePasswordPressed {
    // Display the password generator
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PasswordGenerator" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    PasswordGeneratorViewController *passwordGeneratorViewController = (PasswordGeneratorViewController *)navigationController.topViewController;
    passwordGeneratorViewController.donePressed = ^(PasswordGeneratorViewController *passwordGeneratorViewController, NSString *password) {
        passwordCell.textField.text = password;
        [passwordGeneratorViewController dismissViewControllerAnimated:YES completion:nil];
    };
    passwordGeneratorViewController.cancelPressed = ^(PasswordGeneratorViewController *passwordGeneratorViewController) {
        [passwordGeneratorViewController dismissViewControllerAnimated:YES completion:nil];
    };

    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)passwordGeneratorViewController:(PasswordGeneratorViewController *)controller password:(NSString *)password {
    passwordCell.textField.text = password;
}

- (void)openUrlPressed {
    NSString *text = urlCell.textField.text;
    
    NSURL *url = [NSURL URLWithString:text];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:text]];
    }

    BOOL isHttp = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];

    BOOL webBrowserIntegrated = [[AppSettings sharedInstance] webBrowserIntegrated];
    if (webBrowserIntegrated && isHttp) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"WebBrowser" bundle:nil];
        UINavigationController *navigationController = [storyboard instantiateInitialViewController];
        
        WebBrowserViewController *webBrowserViewController = (WebBrowserViewController *)navigationController.topViewController;
        webBrowserViewController.url = url;
        webBrowserViewController.entry = self.entry;
        
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
