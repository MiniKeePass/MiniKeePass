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

#import <CommonCrypto/CommonDigest.h>
#import "HashedInputStream.h"

@interface HashedInputStream (PrivateMethods)
- (BOOL)readHashedBlock;
@end

@implementation HashedInputStream

- (id)initWithInputStream:(InputStream *)stream {
    self = [super init];
    if (self) {
        inputStream = stream;
        
        buffer = NULL;
        bufferOffset = 0;
        bufferLength = 0;
    }
    return self;
}

- (void)dealloc {
    if (buffer != NULL) {
        free(buffer);
    }
}

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    
    while (remaining > 0) {
        if (bufferOffset == bufferLength) {
            if (![self readHashedBlock]) {
                return bytesLength - remaining;
            }
        }
        
        NSUInteger n = MIN(bufferLength - bufferOffset, remaining);
        memcpy(bytes + offset, buffer + bufferOffset, n);
        
        offset += n;
        remaining -= n;
        
        bufferOffset += n;
    }
    
    return bytesLength;
}

- (BOOL)readHashedBlock {
    if (eof) {
        return NO;
    }
    
    bufferOffset = 0;
    
    // Read the index
    if ([inputStream readInt32] != blockIndex) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid block index" userInfo:nil];
    }
    ++blockIndex;
    
    // Read the hash
    uint8_t hash[32];
    if ([inputStream read:hash length:32] != 32) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read hash" userInfo:nil];
    }
    
    // Read the size
    bufferLength = [inputStream readInt32];
    
    // Check if it's the last block
    if (bufferLength == 0) {
        for (int i = 0; i < 32; ++i) {
            if (hash[i] != 0) {
                @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid hash" userInfo:nil];
            }
        }
        
        eof = true;
        return false;
    }
    
    // Allocate the new buffer
    if (buffer != NULL) {
        free(buffer);
    }
    buffer = malloc(bufferLength);
    
    // Read the block
    if ([inputStream read:buffer length:bufferLength] != bufferLength) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read block" userInfo:nil];
    }
    
    // Verify the hash
    uint8_t result[32];
    CC_SHA256(buffer, bufferLength, result);
    if (memcmp(result, hash, 32) != 0) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid hash" userInfo:nil];
    }
    
    return true;
}

@end
