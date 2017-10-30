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

+ (NSData*)getUInt64BytesFromNumber:(NSNumber *)num {
    uint64_t val = [num unsignedLongLongValue];
    return [self getUInt64Bytes:val];
}

+ (NSData*)getUInt64Bytes:(uint64_t)val {  // Little Endian
    uint8_t buf[8];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    buf[2] = (uint8_t) (val >> 16);
    buf[3] = (uint8_t) (val >> 24);
    buf[4] = (uint8_t) (val >> 32);
    buf[5] = (uint8_t) (val >> 40);
    buf[6] = (uint8_t) (val >> 48);
    buf[7] = (uint8_t) (val >> 56);
    
    return [[NSData alloc] initWithBytes:buf length:8];
}

+ (NSData*)getUInt32BytesFromNumber:(NSNumber *)num {
    uint32_t val = (uint32_t)[num unsignedIntegerValue];
    return [self getUInt32Bytes:val];
}

+ (NSData*)getUInt32Bytes:(uint32_t)val {
    uint8_t buf[4];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    buf[2] = (uint8_t) (val >> 16);
    buf[3] = (uint8_t) (val >> 24);
    
    return [[NSData alloc] initWithBytes:buf length:4];
}

+ (NSData*)getUInt16Bytes:(uint32_t)val {
    uint8_t buf[2];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    
    return [[NSData alloc] initWithBytes:buf length:2];
}

+ (uint64_t)BytesToInt64:(NSData*)data {
    uint8_t *pb;
    
    pb = (uint8_t *)data.bytes;
    
    return ((uint64_t)pb[0]         | ((uint64_t)pb[1] << 8)  | ((uint64_t)pb[2] << 16) |
            ((uint64_t)pb[3] << 24) | ((uint64_t)pb[4] << 32) | ((uint64_t)pb[5] << 40) |
            ((uint64_t)pb[6] << 48) | ((uint64_t)pb[7] << 56));
}

@end
