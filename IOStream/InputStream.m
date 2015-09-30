/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "InputStream.h"

@implementation InputStream

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (NSData *)readData:(NSUInteger)length {
    uint8_t *bytes = calloc(sizeof(uint8_t), length);
    
    [self read:bytes length:length];
    NSData *data = [NSData dataWithBytes:bytes length:length];
    free(bytes);

    return data;
}

- (uint8_t)readInt8 {
    uint8_t value = 0;
    
    [self read:&value length:1];
    
    return value;
}

- (uint16_t)readInt16 {
    uint16_t value = 0;
    
    [self read:&value length:2];
    
    return value;
}

- (uint32_t)readInt32 {
    uint32_t value = 0;
    
    [self read:&value length:4];
    
    return value;
}

- (uint64_t)readInt64 {
    uint64_t value = 0;
    
    [self read:&value length:8];
    
    return value;
}

- (NSString *)readString:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    uint8_t bytes[length];
    
    [self read:bytes length:length];
    
    return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
}

- (NSString *)readCString:(NSUInteger)length encoding:(NSStringEncoding)encoding {
    char str[length];
    
    [self read:str length:length];
    
    return [NSString stringWithCString:str encoding:encoding];
}

- (NSUInteger)skip:(NSUInteger)length {
    NSUInteger n = length;
    NSInteger ret;

    if (length == 0) {
        return 0;
    }

    NSUInteger buflen = MIN(n, 1024);
    uint8_t bytes[buflen];

    while (n > 0) {
        ret = [self read:bytes length:MIN(n, buflen)];
        if (ret < 0) {
            break;
        }

        n -= ret;
    }

    return length - n;
}

- (void)close {
    
}

@end
