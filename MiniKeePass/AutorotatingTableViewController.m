//
//  AutorotatingTableViewController.m
//  MiniKeePass
//
//  Created by John Flanagan on 4/21/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "AutorotatingTableViewController.h"

@implementation AutorotatingTableViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldRotate;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        shouldRotate = YES;
    } else {
        shouldRotate = interfaceOrientation == UIInterfaceOrientationPortrait;
    }
    
    return shouldRotate;
}

@end
