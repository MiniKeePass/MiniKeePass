//
//  AGClock+MKPAdditions.m
//  MiniKeePass
//
//  Created by Mark Hewett on 6/25/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "AGClock+MKPAdditions.h"

@implementation AGClock (MKPAdditions)

- (uint64_t)timeRemainingInCurrentInterval {
    NSTimeInterval seconds = [self.date timeIntervalSince1970];
    uint64_t counter = (uint64_t) (seconds / 30);
    return (uint64_t) ((counter + 1) * 30) - seconds;
}

@end
