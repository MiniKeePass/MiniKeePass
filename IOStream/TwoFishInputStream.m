/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
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

#import "TwoFishInputStream.h"
#import "TwoFishCipher.h"

#define BLOCK_BUFFERSIZE (512*1024)

@interface TwoFishInputStream (PrivateMethods)
- (BOOL)decrypt;
@end

@implementation TwoFishInputStream {
    BlockCipher *cipher;
    
    uint8_t buffer[BLOCK_BUFFERSIZE];
    uint32_t bufferOffset;
    uint32_t bufferSize;    
}

- (id)initWithInputStream:(InputStream *)stream key:(NSData *)key iv:(NSData *)iv {
    self = [super init];
    if (self) {
        inputStream = stream;
        
        cipher = [[TwoFishCipher alloc] init:key iv:iv];
        
        bufferOffset = 0;
        bufferSize = 0;
        eof = NO;
    }
    return self;
}

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;
    
    while (remaining > 0) {
        if (bufferOffset >= bufferSize) {
            if (![self decrypt]) {
                return bytesLength - remaining;
            }
        }
        
        n = MIN(remaining, bufferSize - bufferOffset);       
        memcpy(((uint8_t *)bytes) + offset, buffer + bufferOffset, n);
        
        bufferOffset += n;
        
        offset += n;
        remaining -= n;
    }
    
    return bytesLength;
}

- (BOOL)decrypt {
    NSUInteger n;
    
    if (eof) {
        return NO;
    }
    
    bufferOffset = 0;
    bufferSize = 0;

    n = [inputStream read:buffer length:BLOCK_BUFFERSIZE];
    if (n > 0) {
        [cipher Decrypt:buffer iOffset:0 count:n];
        bufferSize += n;
    }

    if (n < BLOCK_BUFFERSIZE) {
        eof = YES;
    }

    return YES;
}

@end
