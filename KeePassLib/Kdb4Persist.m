//
//  Kdb4Persist.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/26/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Persist.h"

@implementation Kdb4Persist

- (id)initWithTree:(Kdb4Tree*)t andOutputStream:(OutputStream*)stream {
    self = [super init];
    if (self) {
        tree = [t retain];
        outputStream = [stream retain];
    }
    return self;
}

- (void)dealloc {
    [tree release];
    [outputStream release];
    [super dealloc];
}

- (void)persist {
    // FIXME
}

@end
