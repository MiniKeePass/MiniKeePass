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
#import "WebViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import "AeroGearOTP.h"
#import "KdbEntry+MKPAdditions.h"
#import "AGClock+MKPAdditions.h"

#include "OTPAuthBarClock.h"


#define SECTION_HEADER_HEIGHT 46.0f

enum {
    SECTION_DEFAULT_FIELDS,
    SECTION_CUSTOM_FIELDS,
    SECTION_COMMENTS,
    NUM_SECTIONS
};

@interface EntryViewController() {
    TitleFieldCell *titleCell;
    TextFieldCell *usernameCell;
    PasswordFieldCell *passwordCell;
    UrlFieldCell *urlCell;
    TextFieldCell *otpCell;
    TextViewCell *commentsCell;
    
    NSTimer *otpTimer;
}

@property (nonatomic) BOOL isKdb4;
@property (nonatomic, readonly) NSMutableArray *editingStringFields;
@property (nonatomic, readonly) NSArray *entryStringFields;
@property (nonatomic, readonly) NSArray *currentStringFields;

@property (nonatomic, strong) NSMutableArray *filledCells;
@property (nonatomic, readonly) NSArray *defaultCells;

@property (nonatomic, readonly) NSArray *cells;

@end

@implementation EntryViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.allowsSelectionDuringEditing = YES;

        self.navigationItem.rightBarButtonItem = self.editButtonItem;

        UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Entry", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil
                                                                             action:nil];
        self.navigationItem.backBarButtonItem = backBarButtonItem;

        titleCell = [[TitleFieldCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
        titleCell.delegate = self;
        titleCell.textLabel.text = NSLocalizedString(@"Title", nil);
        titleCell.textField.placeholder = NSLocalizedString(@"Title", nil);
        titleCell.textField.enabled = NO;
        titleCell.textFieldCellDelegate = self;
        titleCell.imageButton.adjustsImageWhenHighlighted = NO;
        [titleCell.imageButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];

        usernameCell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
        usernameCell.textLabel.text = NSLocalizedString(@"Username", nil);
        usernameCell.textField.placeholder = NSLocalizedString(@"Username", nil);
        usernameCell.textField.enabled = NO;
        usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        usernameCell.textFieldCellDelegate = self;

        passwordCell = [[PasswordFieldCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
        passwordCell.textLabel.text = NSLocalizedString(@"Password", nil);
        passwordCell.textField.placeholder = NSLocalizedString(@"Password", nil);
        passwordCell.textField.enabled = NO;
        passwordCell.textFieldCellDelegate = self;
        [passwordCell.accessoryButton addTarget:self action:@selector(showPasswordPressed) forControlEvents:UIControlEventTouchUpInside];
        [passwordCell.editAccessoryButton addTarget:self action:@selector(generatePasswordPressed) forControlEvents:UIControlEventTouchUpInside];

        urlCell = [[UrlFieldCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
        urlCell.textLabel.text = NSLocalizedString(@"URL", nil);
        urlCell.textField.placeholder = NSLocalizedString(@"URL", nil);
        urlCell.textField.enabled = NO;
        urlCell.textFieldCellDelegate = self;
        urlCell.textField.returnKeyType = UIReturnKeyDone;
        [urlCell.accessoryButton addTarget:self action:@selector(openUrlPressed) forControlEvents:UIControlEventTouchUpInside];
        
        otpCell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:nil];
        otpCell.textLabel.text = NSLocalizedString(@"OTP", nil);
        otpCell.textField.enabled = NO;
        otpCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        otpCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        otpCell.textFieldCellDelegate = self;
        
        CGFloat clockHeight = otpCell.contentView.frame.size.height * .50;
        otpCell.accessoryView = [[OTPAuthBarClock alloc] initWithFrame:CGRectMake(0, 0, clockHeight, clockHeight) period:30];

        commentsCell = [[TextViewCell alloc] init];
        commentsCell.textView.editable = NO;

        _defaultCells = @[titleCell, usernameCell, passwordCell, urlCell];
        _filledCells = [[NSMutableArray alloc] initWithCapacity:5];

        _editingStringFields = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    self.tableView.sectionFooterHeight = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isNewEntry) {
        [self setEditing:YES animated:NO];
        [titleCell.textField becomeFirstResponder];
        self.isNewEntry = NO;
    }
    
    [self startOTPTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // Hide the password HUD if it's visible
    [MBProgressHUD hideHUDForView:self.view animated:NO];

    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stopOTPTimer];
}

- (void)applicationWillResignActive:(id)sender {
    // Resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [otpCell.textField resignFirstResponder];
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

    [self updateOTP];
}

- (NSArray *)cells {
    return self.editing ? self.defaultCells : self.filledCells;
}

- (void)startOTPTimer {
    if (otpTimer == nil && otpCell.textField.text.length > 0) {
        NSLog(@"Starting OTP update timer");
        // should we update faster?
        otpTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateOTP) userInfo:nil repeats:YES];
    }
}

- (void)stopOTPTimer {
    if (otpTimer != nil) {
        NSLog(@"Stopping OTP update timer");
        [otpTimer invalidate];
        otpTimer = nil;
    }
}

- (void)updateOTP {
    otpCell.textField.text = [self.entry getOtp];
    // Track what cells are filled out
    [self updateFilledCells];
    if ([self.entry getOtpTimeRemaining] < 5) {
        otpCell.textField.textColor = [UIColor redColor];
    }
    else {
        otpCell.textField.textColor = [UIColor blackColor];
    }
}

- (void)updateFilledCells {
    [self.filledCells removeAllObjects];
    for (TextFieldCell *cell in self.defaultCells) {
        if (cell.textField.text.length > 0) {
            [self.filledCells addObject:cell];
        }
    }
    // OTP cell
    if (otpCell.textField.text.length > 0) {
        [self.filledCells addObject:otpCell];
        [self startOTPTimer];
    }
    else {
        [self stopOTPTimer];
    }
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
    [self setEditing:NO animated:YES canceled:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self setEditing:editing animated:animated canceled:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated canceled:(BOOL)canceled {
    [super setEditing:editing animated:animated];

    // Ensure that all updates happen at once
    [self.tableView beginUpdates];

    if (editing == NO) {
        if (canceled) {
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

            // See if we now have an OTP
            [self.entry setIsUpdated];
            [self updateOTP];

            // Save the database document
            [[MiniKeePassAppDelegate appDelegate].databaseDocument save];
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

        titleCell.imageButton.adjustsImageWhenHighlighted = YES;
        commentsCell.textView.editable = YES;

        // Hide the OTP cell, if needed
        if (otpCell.textField.text.length > 0) {
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.filledCells count] - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        self.navigationItem.leftBarButtonItem = nil;

        titleCell.imageButton.adjustsImageWhenHighlighted = NO;
        commentsCell.textView.editable = NO;

        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        // Make the OTP cell visible again, if needed
        if (otpCell.textField.text.length > 0) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.filledCells count] - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }

    // Commit all updates
    [self.tableView endUpdates];
}

- (void)titleFieldCell:(TitleFieldCell *)cell updatedTitle:(NSString *)title {
    self.title = title;
}

#pragma mark - TextFieldCell delegate

- (void)textFieldCellDidEndEditing:(TextFieldCell *)textFieldCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:textFieldCell];

    switch (indexPath.section) {
        case SECTION_CUSTOM_FIELDS: {
            StringField *stringField = [self.editingStringFields objectAtIndex:indexPath.row];
            stringField.value = textFieldCell.textField.text;
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
    static NSString *TextFieldCellIdentifier = @"TextFieldCell";
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
                    cell.textFieldCellDelegate = self;
                    cell.textField.returnKeyType = UIReturnKeyDone;
                }

                StringField *stringField = [self.currentStringFields objectAtIndex:indexPath.row];
                [cell setShowGrayBar:self.editing];

                cell.textLabel.text = stringField.key;
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

    StringFieldViewController *stringFieldViewController = [[StringFieldViewController alloc] initWithStringField:stringField];
    stringFieldViewController.donePressed = ^(FormViewController *formViewController) {
        [self updateStringField:(StringFieldViewController *)formViewController];
    };
    stringFieldViewController.cancelPressed = ^(FormViewController *formViewController) {
        [formViewController dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:stringFieldViewController];

    [self.navigationController presentViewController:navController animated:YES completion:nil];
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

    // Figure out frame for copied label
    NSString *copiedString = NSLocalizedString(@"Copied", nil);
    UIFont *font = [UIFont boldSystemFontOfSize:18];
    CGSize size = [copiedString sizeWithFont:font];
    CGFloat x = (cell.frame.size.width - size.width) / 2.0;
    CGFloat y = (cell.frame.size.height - size.height) / 2.0;

    // Contruct label
    UILabel *copiedLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, size.width, size.height)];
    copiedLabel.text = copiedString;
    copiedLabel.font = font;
    copiedLabel.textAlignment = UITextAlignmentCenter;
    copiedLabel.textColor = [UIColor whiteColor];
    copiedLabel.backgroundColor = [UIColor clearColor];

    // Put cell into "Copied" state
    [cell addSubview:copiedLabel];
    cell.textField.alpha = 0;
    cell.textLabel.alpha = 0;
    cell.accessoryView.hidden = YES;

    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.5 animations:^{
            // Return to normal state
            copiedLabel.alpha = 0;
            cell.textField.alpha = 1;
            cell.textLabel.alpha = 1;
            [cell setSelected:NO animated:YES];
        } completion:^(BOOL finished) {
            cell.accessoryView.hidden = NO;
            [copiedLabel removeFromSuperview];
            self.tableView.allowsSelection = YES;
        }];
    });
}

#pragma mark - StringField related

- (void)editStringField:(NSIndexPath *)indexPath {
    StringField *stringField = [self.editingStringFields objectAtIndex:indexPath.row];

    StringFieldViewController *stringFieldViewController = [[StringFieldViewController alloc] initWithStringField:stringField];
    stringFieldViewController.object = indexPath;
    stringFieldViewController.donePressed = ^(FormViewController *formViewController) {
        [self updateStringField:(StringFieldViewController *)formViewController];
    };
    stringFieldViewController.cancelPressed = ^(FormViewController *formViewController) {
        [formViewController dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:stringFieldViewController];

    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)updateStringField:(StringFieldViewController *)stringFieldController {
    if (stringFieldController.object == nil) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
        [self.editingStringFields addObject:stringFieldController.stringField];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSIndexPath *indexPath = (NSIndexPath *)stringFieldController.object;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [stringFieldController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image related

- (void)setSelectedImageIndex:(NSUInteger)index {
    _selectedImageIndex = index;

    UIImage *image = [[ImageFactory sharedInstance] imageForIndex:index];
    [titleCell.imageButton setImage:image forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    if (self.tableView.isEditing) {
        ImageSelectionViewController *imageSelectionViewController = [[ImageSelectionViewController alloc] init];
        imageSelectionViewController.imageSelectionView.delegate = self;
        imageSelectionViewController.imageSelectionView.selectedImageIndex = _selectedImageIndex;
        [self.navigationController pushViewController:imageSelectionViewController animated:YES];
    }
}

- (void)imageSelectionView:(ImageSelectionView *)imageSelectionView selectedImageIndex:(NSUInteger)imageIndex {
    [self setSelectedImageIndex:imageIndex];
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
    PasswordGeneratorViewController *passwordGeneratorViewController = [[PasswordGeneratorViewController alloc] init];
    passwordGeneratorViewController.delegate = self;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordGeneratorViewController];

    [self presentModalViewController:navigationController animated:YES];
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
        WebViewController *webViewController = [[WebViewController alloc] init];
        webViewController.entry = self.entry;
        [self.navigationController pushViewController:webViewController animated:YES];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
