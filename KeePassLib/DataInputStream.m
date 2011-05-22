//
//  DataInputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "DataInputStream.h"

@implementation DataInputStream

- (id)initWithData:(NSData*)d {
    self = [super init];
    if (self) {
        data = [d retain];
        dataOffset = 0;
    }
    return self;
}

- (void)dealloc {
    [data release];
    [super dealloc];
}

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength {
    NSRange range;
    range.location = dataOffset;
    range.length = MIN([data length] - dataOffset, bytesLength);
    
    [data getBytes:bytes range:range];
    
    dataOffset += range.length;
    
    return range.length;
}

@end
