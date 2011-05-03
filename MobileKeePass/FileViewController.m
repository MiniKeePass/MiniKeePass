//
//  FileViewController.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "FileViewController.h"
#import "MobileKeePassAppDelegate.h"
#import "Database.h"

@implementation FileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Files";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get the document's directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    files = [[dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.kdb'"]] retain];
    
    [self.tableView reloadData];
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

- (BOOL)passwordEntryController:(PasswordEntryController*)controller passwordEntered:(NSString*)password {
    BOOL shouldDismiss = YES;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Add the filename to the documents directory
    NSString *path = [documentsDirectory stringByAppendingPathComponent:selectedFile];
    
    // Load the database
    DatabaseDocument *dd = [[DatabaseDocument alloc] init];
    enum DatabaseError error = [dd open:path password:password];
    if (error == NO_ERROR) {
        MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        appDelegate.databaseDocument = dd;
        
        [[NSUserDefaults standardUserDefaults] setValue:path forKey:@"lastFilename"];
        
        [self.navigationController popToRootViewControllerAnimated:NO];
    } else if (error == WRONG_PASSWORD) {
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
