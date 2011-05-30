//
//  InputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "InputStream.h"

@implementation InputStream

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (NSData*)readData:(NSUInteger)length {
    uint8_t bytes[length];
    
    [self read:bytes length:length];
    
    return [NSData dataWithBytes:bytes length:length];
}

- (uint8_t)readInt8 {
    uint8_t value;
    
    [self read:&value length:1];
    
    return value;
}

- (uint16_t)readInt16 {
    uint16_t value;
    
    [self read:&value length:2];
    
    return value;
}

- (uint32_t)readInt32 {
    uint32_t value;
    
    [self read:&value length:4];
    
    return value;
}

- (uint64_t)readInt64 {
    uint64_t value;
    
    [self read:&value length:8];
    
    return value;
}

- (NSString*)readString:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    uint8_t bytes[length];
    
    [self read:bytes length:length];
    
    return [[[NSString alloc] initWithBytes:bytes length:length encoding:encoding] autorelease];
}

- (NSString*)readCString:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    char str[length];
    
    [self read:str length:length];
    
    return [NSString stringWithCString:str encoding:encoding];
}

- (void)close {
    
}

@end
