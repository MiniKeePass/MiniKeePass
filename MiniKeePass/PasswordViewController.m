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

#import "PasswordViewController.h"

#define ROW_KEY_FILE 1

@implementation PasswordViewController

@synthesize passwordTextField;
@synthesize keyFileCell;

- (id)initWithFilename:(NSString*)filename {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Password", nil);
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
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    // Update the cell text
    [keyFileCell setSelectedIndex:selectedIndex];
}

@end
