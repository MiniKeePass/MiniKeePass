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

@implementation EntryViewController

@synthesize isNewEntry;
@synthesize entry;

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
        
        canceled = NO;
    }
    return self;
}

- (void)dealloc {
    [titleCell release];
    [usernameCell release];
    [passwordCell release];
    [urlCell release];
    [commentsCell release];
    [entry release];
    [defaultCells release];
    [super dealloc];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    // Save the database or reset the entry
    if (editing == NO && !canceled) {
        entry.title = titleCell.textField.text;
        entry.image = selectedImageIndex;
        entry.username = usernameCell.textField.text;
        entry.password = passwordCell.textField.text;
        entry.url = urlCell.textField.text;
        entry.notes = commentsCell.textView.text;
        
        appDelegate.databaseDocument.dirty = YES;
        
        // Save the database document
        [appDelegate.databaseDocument save];
    } else {
        [self setEntry:entry];
    }
    
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
        
        canceled = NO;

        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        
        [titleCell.textField resignFirstResponder];
        [usernameCell.textField resignFirstResponder];
        [passwordCell.textField resignFirstResponder];
        [urlCell.textField resignFirstResponder];
        [commentsCell.textView resignFirstResponder];
        
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Mark the view as not being canceled
    canceled = NO;
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    if (isNewEntry) {
        [self setEditing:YES animated:NO];
        isNewEntry = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    originalHeight = self.view.frame.size.height;
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!canceled && [self isDirty]) {
        entry.title = titleCell.textField.text;
        entry.image = selectedImageIndex;
        entry.username = usernameCell.textField.text;
        entry.password = passwordCell.textField.text;
        entry.url = urlCell.textField.text;
        entry.notes = commentsCell.textView.text;
        
        appDelegate.databaseDocument.dirty = YES;
        
        // Save the database document
        [appDelegate.databaseDocument save];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEntry:(KdbEntry *)e {
    [entry release];
    
    entry = [e retain];
    self.isKdb4 = [entry isKindOfClass:[Kdb4Entry class]];
    
    // Update the fields
    self.title = entry.title;
    titleCell.textField.text = entry.title;
    [self setSelectedImageIndex:entry.image];
    usernameCell.textField.text = entry.username;
    passwordCell.textField.text = entry.password;
    urlCell.textField.text = entry.url;
    commentsCell.textView.text = entry.notes;
}

- (KdbEntry *)entry {
    return entry;
}

- (void)applicationWillResignActive:(id)sender {
    // Resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (void)cancelPressed {
    canceled = YES;
    [self setEditing:NO animated:YES];
}

BOOL stringsEqual(NSString *str1, NSString *str2) {
    str1 = str1 == nil ? @"" : [str1 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    str2 = str2 == nil ? @"" : [str2 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    return [str1 isEqualToString:str2];
}

- (BOOL)isDirty {
    return !(stringsEqual(entry.title, titleCell.textField.text) &&
        entry.image == selectedImageIndex &&
        stringsEqual(entry.username, usernameCell.textField.text) &&
        stringsEqual(entry.password, passwordCell.textField.text) &&
        stringsEqual(entry.url, urlCell.textField.text) &&
        stringsEqual(entry.notes, commentsCell.textView.text));
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        return NO;
    }
    return YES;
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
            return self.isKdb4 ? [((Kdb4Entry*)entry).stringFields count] : 0;
        case 2:
            return 1;
    }
    
    return 0;
}

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
            if ((self.isKdb4 ? [((Kdb4Entry*)entry).stringFields count] : 0) != 0) {
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
                    if (tableView.isEditing || usernameCell.textField.text.length > 0) {
                        return usernameCell;
                    }
                case 2:
                    if (tableView.isEditing || passwordCell.textField.text.length > 0) {
                        return passwordCell;
                    }
                case 3:
                    return urlCell;
            }
        }
        case 1: {
            StringField *stringField = [((Kdb4Entry*)entry).stringFields objectAtIndex:indexPath.row];
            
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
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    TextFieldCell *cell = (TextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
    pasteboard.string = cell.textField.text;
    
    ATMHud *hud = [[ATMHud alloc] initWithDelegate:self];
    [hud setCaption:NSLocalizedString(@"Coppied", nil)];
    
    [appDelegate.window addSubview:hud.view];
    [hud show];
    [hud hideAfter:1.5];
    [hud release];
}

- (NSUInteger)selectedImageIndex {
    return selectedImageIndex;
}

- (void)setSelectedImageIndex:(NSUInteger)index {
    selectedImageIndex = index;
    
    UIImage *selectedImage = [appDelegate loadImage:index];

    titleCell.accessoryView = [[[UIImageView alloc] initWithImage:selectedImage] autorelease];
    if (titleCell.editAccessoryButton == nil) {
        titleCell.editAccessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [titleCell.editAccessoryButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [titleCell.editAccessoryButton setImage:selectedImage forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    if (self.tableView.isEditing) {
        ImagesViewController *imagesViewController = [[ImagesViewController alloc] init];
        imagesViewController.delegate = self;
        [imagesViewController setSelectedImage:selectedImageIndex];
        [self.navigationController pushViewController:imagesViewController animated:YES];
        [imagesViewController release];
    }
}

- (void)imagesViewController:(ImagesViewController *)controller imageSelected:(NSUInteger)index {
    [self setSelectedImageIndex:index];
}

- (void)showPasswordPressed {
    ATMHud *hud = [[ATMHud alloc] initWithDelegate:self];
    [hud setCaption:entry.password];
    
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
