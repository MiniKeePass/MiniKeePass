//
//  OutputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "OutputStream.h"

@implementation OutputStream

- (NSUInteger)write:(const void*)bytes length:(NSUInteger)bytesLength {
    @throw [NSException exceptionWithName:@"AbstractMethod" reason:@"write:length:" userInfo:nil];
}

- (NSUInteger)write:(NSData*)data {
    return [self write:[data bytes] length:[data length]];
}

- (void)writeInt8:(uint8_t)value {
    [self write:&value length:1];
}

- (void)writeInt16:(uint16_t)value {
    [self write:&value length:2];
}

- (void)writeInt32:(uint32_t)value {
    [self write:&value length:4];
}

- (void)writeInt64:(uint64_t)value {
    [self write:&value length:8];
}

- (void)close {
    
}

@end
