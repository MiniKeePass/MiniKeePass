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

#import "FileViewController.h"
#import "OpenHelpView.h"
#import "MobileKeePassAppDelegate.h"
#import "SFHFKeychainUtils.h"

@implementation FileViewController

@synthesize selectedFile;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Files";
}

- (void)displayHelpPage {
    OpenHelpView *openHelpView = [[OpenHelpView alloc] init];
    [self.view addSubview:openHelpView];
    [openHelpView release];
    
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSArray *filenames = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.kdb'"]];
    files = [[NSMutableArray arrayWithArray:filenames] retain];
    
    // Show the help view if there are no files
    if ([files count] == 0) {
        [self displayHelpPage];
    } else {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

}

- (void)dealloc {
    [files release];
    [selectedFile release];
    [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
    cell.textLabel.text = [files objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (selectedFile != nil) {
        [selectedFile release];
    }
    selectedFile = [[files objectAtIndex:indexPath.row] retain];
    
    PasswordEntryController *passwordEntryController = [[PasswordEntryController alloc] init];
    passwordEntryController.delegate = self;
    
    [self presentModalViewController:passwordEntryController animated:YES];
    
    [passwordEntryController release];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filename = [files objectAtIndex:indexPath.row];

        //Retrieve document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
        [fileManager release];
        
        [files removeObject:filename];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (BOOL)passwordEntryController:(PasswordEntryController*)controller passwordEntered:(NSString*)password {
    BOOL shouldDismiss = YES;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Add the filename to the documents directory
    NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFile];
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    enum DatabaseError databaseError = [dd open:path password:password];
    if (databaseError == NO_ERROR) {
        MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        appDelegate.databaseDocument = dd;
        
        [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"lastFilename"];
        
        // Store the password in the keychain
        NSError *error;
        [SFHFKeychainUtils storeUsername:path andPassword:password forServiceName:@"net.fizzawizza.MobileKeePass" updateExisting:YES error:&error];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
    } else if (databaseError == WRONG_PASSWORD) {
        shouldDismiss = NO;
        controller.statusLabel.text = @"Wrong Password";
    } else {
        shouldDismiss = NO;
        controller.statusLabel.text = @"Failed to open database";
    }
    [dd release];
    
    return shouldDismiss;
}

@end
