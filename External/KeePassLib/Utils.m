//
//  Utils.m
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (BOOL)emptyString:(NSString*)str{
    return (!str || ![str length]);
}

+ (NSData*)randomBytes:(uint32_t)length {
    uint8_t buffer[length];
    uint32_t *ptr = (uint32_t*)buffer;
    uint32_t n = length / 4;
    uint32_t i;
    
    for (i = 0; i < n; i++) {
        *ptr++ = arc4random();
    }
    
    return [NSData dataWithBytes:buffer length:length];
}

+ (NSString*)hexDumpData:(NSData*)data {
    return [self hexDumpBytes:data.bytes length:data.length];
}

+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length {
    NSMutableString *string = [[NSMutableString alloc] init];
    const uint8_t *bytes = (const uint8_t*)buffer;
    int i;
    int j;
    
    for (i = 0; i < length; i += 16) {
        // Print out the address
        [string appendFormat:@"%08X ", i];
        
        // Print out the hex
        for (j = 0; j < 16; j++) {
            int off = i + j;
            if (off < length) {
                // Print the hex digit
                [string appendFormat:@" %02X", bytes[off]];
            } else {
                // Pad out the last row
                [string appendString:@"   "];
            }
            
            // Add a space every 4 bytes
            if (((j + 1) % 4) == 0) {
                [string appendString:@" "];
            }
        }
        
        // Print out the ASCII
        [string appendString:@" |"];
        for (j = 0; j < 16; j++) {
            int off = i + j;
            if (off < length) {
                // Print the ASCII character
                unsigned char c = bytes[off];
                if (!isprint(c)) {
                    c = '.';
                }
                [string appendFormat:@"%c", c];
            } else {
                // Pad out the last row
                [string appendString:@" "];
            }
        }
        [string appendString:@"|\n"];
    }
    
    return string;
}

@end
