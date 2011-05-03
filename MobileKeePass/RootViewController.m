//
//  RootViewController.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "RootViewController.h"
#import "MobileKeePassAppDelegate.h"

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    fileViewController = nil;
    
    self.title = @"KeePass";
    
    UIBarButtonItem *openButton = [[UIBarButtonItem alloc] initWithTitle:@"Open" style:UIBarButtonItemStyleBordered target:self action:@selector(openPressed:)];
    self.navigationItem.leftBarButtonItem = openButton;
    [openButton release];
}

- (void)viewWillAppear:(BOOL)animated {
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (appDelegate.databaseDocument != nil) {
        group = [appDelegate.databaseDocument.database rootGroup];
        
        [self.tableView reloadData];
    }
}

- (void)dealloc {
    [fileViewController release];
    [super dealloc];
}

- (void)openPressed:(id)sender {
    if (fileViewController == nil) {
        fileViewController = [[FileViewController alloc] initWithStyle:UITableViewStylePlain];
    }
    
    // Push the FileViewController onto the view stack
    [self.navigationController pushViewController:fileViewController animated:YES];
}

@end
