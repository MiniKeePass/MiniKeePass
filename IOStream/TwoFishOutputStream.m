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

#import "TwoFishOutputStream.h"
#import "TwoFishCipher.h"

@interface TwoFishOutputStream (PrivateMethods)
- (void)writeDataBlock;
@end

@implementation TwoFishOutputStream {
    uint32_t blockIndex;
    
    uint8_t *buffer;
    uint32_t bufferOffset;
    uint32_t bufferLength;
}

- (id)initWithOutputStream:(OutputStream *)stream key:(NSData *)key iv:(NSData *)iv {
    self = [super init];
    if (self) {
        outputStream = stream;
        
        cipher = [[TwoFishCipher alloc] init:key iv:iv];
        
        bufferOffset = 0;
        bufferLength = 1024*64*TWOFISH_BLOCK_SIZE;
        buffer = malloc(bufferLength);
    }
    return self;
}

- (void)dealloc {
    free(buffer);
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger length = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;

    while (length > 0) {
        if (bufferOffset == bufferLength) {
            [self writeDataBlock];
        }
        
        n = MIN(bufferLength - bufferOffset, length);
        memcpy(buffer + bufferOffset, bytes + offset, n);
        
        bufferOffset += n;
        
        offset += n;
        length -= n;
    }
    
    return bytesLength;
}

- (void)writeDataBlock {
    int padLen;
    
    padLen = TWOFISH_BLOCK_SIZE - (bufferOffset - ((bufferOffset/TWOFISH_BLOCK_SIZE) * TWOFISH_BLOCK_SIZE ));
    if (padLen == 16) padLen = 0;

    for (int i = 0; i < padLen; i++) {
        buffer[i + bufferOffset] = (uint8_t)padLen;
    }
    
    bufferOffset += padLen;
    
    // Encrypt the data buffer
    [cipher Encrypt:buffer iOffset:0 count:bufferOffset];
    // Write the encrypted data
    [outputStream write:buffer length:bufferOffset];
    bufferOffset = 0;
}

- (void)close {
    // Write the last encrypted data
    if (bufferOffset > 0) {
        [self writeDataBlock];
    }
    
    [outputStream close];
}

@end
