//
//  DDXMLNode+MKPAdditions.m
//  MiniKeePass
//
//  Created by Jason Rush on 9/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "DDXMLElement+MKPAdditions.h"

@implementation DDXMLElement (MKPAdditions)

- (void)removeChild:(DDXMLNode *)child {
    int idx = [child index];

    if (idx >= 0) {
        [self removeChildAtIndex:idx];
    }
}

@end
