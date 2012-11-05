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

#import "EntryViewController.h"
#import "Kdb4Node.h"

@interface EntryViewController() {
    MiniKeePassAppDelegate *appDelegate;
    TitleFieldCell *titleCell;
    TextFieldCell *usernameCell;
    PasswordFieldCell *passwordCell;
    UrlFieldCell *urlCell;
    TextViewCell *commentsCell;
    
    NSArray *defaultCells;
    
    BOOL canceled;
}

@property (nonatomic) BOOL isKdb4;

@end

@implementation EntryViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.delaysContentTouches = YES;

        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        titleCell = [[TitleFieldCell alloc] init];
        titleCell.textLabel.text = NSLocalizedString(@"Title", nil);
        titleCell.textField.placeholder = NSLocalizedString(@"Title", nil);
        titleCell.textField.enabled = NO;
        titleCell.textFieldCellDelegate = self;
        titleCell.imageButton.adjustsImageWhenHighlighted = NO;
        [titleCell.imageButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        usernameCell = [[TextFieldCell alloc] init];
        usernameCell.textLabel.text = NSLocalizedString(@"Username", nil);
        usernameCell.textField.placeholder = NSLocalizedString(@"Username", nil);
        usernameCell.textField.enabled = NO;
        usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        usernameCell.textFieldCellDelegate = self;
        
        passwordCell = [[PasswordFieldCell alloc] init];
        passwordCell.textLabel.text = NSLocalizedString(@"Password", nil);
        passwordCell.textField.placeholder = NSLocalizedString(@"Password", nil);
        passwordCell.textField.enabled = NO;
        passwordCell.textFieldCellDelegate = self;
        [passwordCell.accessoryButton addTarget:self action:@selector(showPasswordPressed) forControlEvents:UIControlEventTouchUpInside];
        [passwordCell.editAccessoryButton addTarget:self action:@selector(generatePasswordPressed) forControlEvents:UIControlEventTouchUpInside];
        
        urlCell = [[UrlFieldCell alloc] init];
        urlCell.textLabel.text = NSLocalizedString(@"URL", nil);
        urlCell.textField.placeholder = NSLocalizedString(@"URL", nil);
        urlCell.textField.enabled = NO;
        urlCell.textFieldCellDelegate = self;
        urlCell.textField.returnKeyType = UIReturnKeyDone;
        
        defaultCells = [@[titleCell, usernameCell, passwordCell, urlCell] retain];
        
        commentsCell = [[TextViewCell alloc] init];
    }
    return self;
}

- (void)dealloc {
    [titleCell release];
    [usernameCell release];
    [passwordCell release];
    [urlCell release];
    [commentsCell release];
    [defaultCells release];
    [_entry release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Mark the view as not being canceled
    canceled = NO;
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    if (self.isNewEntry) {
        [self setEditing:YES animated:NO];
        self.isNewEntry = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
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
    [_entry release];
    
    _entry = [e retain];
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

- (void)cancelPressed {
    canceled = YES;
    [self setEditing:NO animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Save the database or reset the entry
    if (editing == NO && !canceled) {
        self.entry.title = titleCell.textField.text;
        self.entry.image = self.selectedImageIndex;
        self.entry.username = usernameCell.textField.text;
        self.entry.password = passwordCell.textField.text;
        self.entry.url = urlCell.textField.text;
        self.entry.notes = commentsCell.textView.text;
        
        appDelegate.databaseDocument.dirty = YES;
        
        // Save the database document
        [appDelegate.databaseDocument save];
    } else {
        [self setEntry:self.entry];
    }
    
    // Find empty text field cells
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:3];
    for (TextFieldCell *cell in defaultCells) {
        cell.textField.enabled = editing;
        if (cell.textField.text.length == 0) {
            // Add empty cells to the list of cells that need to be added when editing
            [paths addObject:[NSIndexPath indexPathForRow:[defaultCells indexOfObject:cell] inSection:0]];
        }
    }
    
    if (editing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];
                
        titleCell.imageButton.adjustsImageWhenHighlighted = YES;
        canceled = NO;
        
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        
        [titleCell.textField resignFirstResponder];
        [usernameCell.textField resignFirstResponder];
        [passwordCell.textField resignFirstResponder];
        [urlCell.textField resignFirstResponder];
        [commentsCell.textView resignFirstResponder];
        
        titleCell.imageButton.adjustsImageWhenHighlighted = NO;
        
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)textFieldCellWillReturn:(TextFieldCell *)textFieldCell {
    if (textFieldCell == titleCell) {
        [usernameCell.textField becomeFirstResponder];
    } else if (textFieldCell == usernameCell) {
        [passwordCell.textField becomeFirstResponder];
    } else if (textFieldCell == passwordCell) {
        [urlCell.textField becomeFirstResponder];
    } else if (textFieldCell == urlCell) {
        [urlCell.textField resignFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int filledCells = 1; // Title is always filled out

    switch (section) {
        case 0:
            if (tableView.isEditing) {
                return [defaultCells count];
            }
            
            for (TextFieldCell* cell in @[usernameCell, passwordCell, urlCell]) {
                if (cell.textField.text.length > 0) {
                    filledCells++;
                }
            }
            
            return filledCells;
        case 1:
            return self.isKdb4 ? [((Kdb4Entry*)self.entry).stringFields count] : 0;
        case 2:
            return 1;
    }
    
    return 0;
}

# pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
        case 1:
            return 40;
        case 2:
            return 104;
    }
    
    return 40;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
        case 1:
            if (self.isKdb4 ? [((Kdb4Entry*)self.entry).stringFields count] : 0) {
                return NSLocalizedString(@"Custom Fields", nil);
            } else {
                return nil;
            }
        case 2:
            return NSLocalizedString(@"Comments", nil);
    }
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return UITableViewCellEditingStyleNone;
        case 1:
            return UITableViewCellEditingStyleDelete;
        case 2:
            return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return YES;
    } else {
        return NO;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    return titleCell;
                case 1:
                    if ((tableView.isEditing || usernameCell.textField.text.length > 0) && [usernameCell superview] == nil) {
                        return usernameCell;
                    }
                case 2:
                    if ((tableView.isEditing || passwordCell.textField.text.length > 0) && [passwordCell superview] == nil) {
                        return passwordCell;
                    }
                case 3:
                    return urlCell;
            }
        }
        case 1: {
            StringField *stringField = [((Kdb4Entry*)self.entry).stringFields objectAtIndex:indexPath.row];
            
            TextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            }
            cell.textLabel.text = stringField.name;
            cell.textField.text = stringField.value;
            return cell;
        }
        case 2: {
            return commentsCell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.allowsSelection = NO;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    TextFieldCell *cell = (TextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
    pasteboard.string = cell.textField.text;
    
    // Figure out frame for copied label
    NSString *copiedString = NSLocalizedString(@"Coppied", nil);
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
            [copiedLabel release];
            tableView.allowsSelection = YES;
        }];
    });
}

#pragma mark - Image related

- (void)setSelectedImageIndex:(NSUInteger)index {
    _selectedImageIndex = index;

    [titleCell.imageButton setImage:[appDelegate loadImage:index] forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    if (self.tableView.isEditing) {
        ImagesViewController *imagesViewController = [[ImagesViewController alloc] init];
        imagesViewController.delegate = self;
        [imagesViewController setSelectedImage:self.selectedImageIndex];
        [self.navigationController pushViewController:imagesViewController animated:YES];
        [imagesViewController release];
    }
}

- (void)imagesViewController:(ImagesViewController *)controller imageSelected:(NSUInteger)index {
    [self setSelectedImageIndex:index];
}

#pragma mark - Password Display

- (void)showPasswordPressed {
    ATMHud *hud = [[ATMHud alloc] initWithDelegate:self];
    NSString *caption = self.entry.password;
    UIFont *captionFont = [UIFont fontWithName:@"Andale Mono" size:24];
    CGSize captionSize;
    
    [hud setCaption:caption];
    [hud setCaptionFont:captionFont];
    
    CGFloat size = 300 - hud.padding;
    captionSize = [caption sizeWithFont:captionFont constrainedToSize:CGSizeMake(size, size) lineBreakMode:UILineBreakModeWordWrap];
    
    captionSize.width += 2 * hud.padding;
    captionSize.height += 2 * hud.padding;

    [hud setFixedSize:captionSize];
    
    [appDelegate.window addSubview:hud.view];
    [hud show];
    [hud release];
}

- (void)userDidTapHud:(ATMHud *)_hud {
    [_hud hide];
}

- (void)hudDidDisappear:(ATMHud *)_hud {
    [_hud.view removeFromSuperview];
}

#pragma mark - Password Generation

- (void)generatePasswordPressed {
    PasswordGeneratorViewController *passwordGeneratorViewController = [[PasswordGeneratorViewController alloc] init];
    passwordGeneratorViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordGeneratorViewController];
    
    [self presentModalViewController:navigationController animated:YES];

    [navigationController release];
    [passwordGeneratorViewController release];
}

- (void)passwordGeneratorViewController:(PasswordGeneratorViewController *)controller password:(NSString *)password {
    passwordCell.textField.text = password;
}

@end
