//
//  DataOutputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "DataOutputStream.h"

@implementation DataOutputStream

@synthesize data;

- (id)init {
    self = [super init];
    if (self) {
        data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc {
    [data release];
    [super dealloc];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    [data appendBytes:bytes length:bytesLength];
    return bytesLength;
}

@end
