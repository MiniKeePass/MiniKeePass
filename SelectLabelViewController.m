//
//  SelectLabelViewController.m
//  MiniKeePass
//
//  Created by John on 12/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "SelectLabelViewController.h"
#import "CreateCustomLabelViewController.h"
#import "AppSettings.h"

@interface SelectLabelViewController ()

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation SelectLabelViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Label";
        _items = [[NSMutableArray alloc] initWithArray:[AppSettings sharedInstance].customLabels];

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];

        self.navigationItem.rightBarButtonItem = self.editButtonItem;

        self.selectedIndex = -1;
    }
    return self;
}

- (void)dealloc {
    [_items release];
    [_object release];
    [super dealloc];
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setCurrentLabel:(NSString *)currentLabel {
    int index = 0;
    for (NSString *label in self.items) {
        if ([label isEqualToString:currentLabel]) {
            self.selectedIndex = index;
        }
        index++;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return self.items.count;
        case 1:
            return 1;
        default:
            return 0;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.items removeObjectAtIndex:indexPath.row];
    [AppSettings sharedInstance].customLabels = self.items;

    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = [self.items objectAtIndex:indexPath.row];
            if (indexPath.row == self.selectedIndex) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.textLabel.textColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [UIColor blackColor];
            }
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Add Custom Label", nil);
            break;

        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row != self.selectedIndex) {
                // Remove the checkmark from the current selection
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [UIColor blackColor];

                // Add the checkmark to the new selection
                cell = [tableView cellForRowAtIndexPath: indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.textLabel.textColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1];

                NSString *label = [self.items objectAtIndex:indexPath.row];

                // Notify the delegate
                if ([self.delegate respondsToSelector:@selector(selectionLabelViewController:selectedLabel:forObject:)]) {
                    [self.delegate selectionLabelViewController:self selectedLabel:label forObject:self.object];
                }
            }

            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case 1: {
            CreateCustomLabelViewController *customLabelViewController = [[CreateCustomLabelViewController alloc] initWithStyle:UITableViewStyleGrouped];
            customLabelViewController.delegate = self;

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:customLabelViewController];
            [customLabelViewController release];

            [self.navigationController presentViewController:navController animated:YES completion:nil];
            [navController release];
            break;
        }
        default:
            break;
    }
}

#pragma mark -

- (void)createCustomLabelViewController:(CreateCustomLabelViewController *)controller createdLabel:(NSString *)string {
    int index = self.items.count;
    [self.items addObject:string];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [[AppSettings sharedInstance] setCustomLabels:self.items];

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
