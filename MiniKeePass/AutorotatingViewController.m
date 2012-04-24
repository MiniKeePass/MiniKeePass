//
//  AutorotatingViewController.m
//  MiniKeePass
//
//  Created by Mark Hewett on 4/8/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "AutorotatingViewController.h"

@implementation AutorotatingViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldRotate;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        shouldRotate = YES;
    } else {
        shouldRotate = interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
    
    return shouldRotate;
}

@end
