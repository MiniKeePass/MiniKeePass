//
//  SplashScreenViewController.m
//  MiniKeePass
//
//  Created by John Flanagan on 9/6/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "SplashScreenViewController.h"


@implementation SplashScreenViewController

- (id)init {
    self = [super init];
    
    if(self != nil) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Default"]];
    }
    
    return self;
}

@end
