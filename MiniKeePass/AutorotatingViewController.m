//
//  AutorotatingViewController.m
//  MiniKeePass
//
//  Created by Mark Hewett on 4/8/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "AutorotatingViewController.h"

@implementation AutorotatingViewController

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
