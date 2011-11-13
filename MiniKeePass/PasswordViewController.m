//
//  PasswordViewController.m
//  MiniKeePass
//
//  Created by Jason Rush on 8/11/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PasswordViewController.h"

#define ROW_KEY_FILE 1

@implementation PasswordViewController

@synthesize passwordTextField;
@synthesize keyFileCell;

- (id)initWithFilename:(NSString*)filename {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Password", nil);
        self.headerTitle = NSLocalizedString(@"Password", nil);
        self.footerTitle = [NSString stringWithFormat:NSLocalizedString(@"Enter the password and/or select the keyfile for the %@ database.", nil), filename];
        
        passwordTextField = [[UITextField alloc] init];
        passwordTextField.placeholder = NSLocalizedString(@"Password", nil);
        passwordTextField.secureTextEntry = YES;
        passwordTextField.returnKeyType = UIReturnKeyDone;
        passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        passwordTextField.delegate = self;
        
        // Create an array to hold the possible keyfile choices
        NSMutableArray *keyFileChoices = [NSMutableArray arrayWithObject:NSLocalizedString(@"None", nil)];
        
        // Get the documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Get the list of key files in the documents directory
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        NSArray *files = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!(self ENDSWITH '.kdb') && !(self ENDSWITH '.kdbx') && !(self BEGINSWITH '.')"]];
        [keyFileChoices addObjectsFromArray:files];
        
        keyFileCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Key File", nil) choices:keyFileChoices selectedIndex:0];
        
        self.controls = [NSArray arrayWithObjects:passwordTextField, keyFileCell, nil];
        self.navigationItem.rightBarButtonItem = nil;
    }
    return self;
}

- (void)dealloc {
    [passwordTextField release];
    [keyFileCell release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == ROW_KEY_FILE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Key File", nil);
        selectionListViewController.items = keyFileCell.choices;
        selectionListViewController.selectedIndex = keyFileCell.selectedIndex;
        selectionListViewController.delegate = self;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
        [selectionListViewController release];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    // Update the cell text
    [keyFileCell setSelectedIndex:selectedIndex];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([delegate respondsToSelector:@selector(formViewController:button:)]) {
        [delegate formViewController:self button:FormViewControllerButtonOk];
    }
    return YES;
}

@end
