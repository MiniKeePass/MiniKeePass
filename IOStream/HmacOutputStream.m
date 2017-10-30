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

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "Utils.h"
#import "HmacOutputStream.h"
#import "HmacInputStream.h"

#define HMAC_BLOCK_SIZE     1024*1024

@interface HmacOutputStream (PrivateMethods)
- (BOOL)readHmacBlock;
@end

@implementation HmacOutputStream

- (id)initWithOutputStream:(OutputStream *)stream key:(NSData *)hkey {
    self = [super init];
    if (self) {
        if (stream == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Bad Value" userInfo:nil];
        }
        if ([hkey length] != 64) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Key length error" userInfo:nil];
        }
        outputStream = stream;
        
        buffer = malloc(HMAC_BLOCK_SIZE);
        bufferOffset = 0;
        bufferLength = HMAC_BLOCK_SIZE;

        blockIndex = 0;
        
        hmacKey = hkey;
    }
    return self;
}

- (void)dealloc {
    if (buffer != NULL) {
        free(buffer);
    }
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger length = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;
    
    while (length > 0) {
        if (bufferOffset == bufferLength) {
            [self writeHmacBlock];
        }
        
        n = MIN(bufferLength - bufferOffset, length);
        memcpy(buffer + bufferOffset, bytes + offset, n);
        
        bufferOffset += n;
        
        offset += n;
        length -= n;
    }
    
    return bytesLength;
}

- (void)writeHmacBlock {
    uint8_t calcHmac[32];

    NSData *blockKey = [self getHMACKey];
    NSData *idxBytes = [Utils getUInt64Bytes:blockIndex];
    NSData *sizeBytes = [Utils getUInt32Bytes:bufferOffset];

    // Compute the Hmac-SHA256 hash
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, blockKey.bytes, [blockKey length]);
    CCHmacUpdate(&ctx, idxBytes.bytes, [idxBytes length]);
    CCHmacUpdate(&ctx, sizeBytes.bytes, [sizeBytes length]);
    CCHmacUpdate(&ctx, buffer, bufferOffset);
    CCHmacFinal(&ctx, calcHmac);

    // Write out the HMAC Value
    [outputStream write:calcHmac length:32];
    
    // Write out the block size
    [outputStream writeInt32:bufferOffset];

    // Write out the data block
    if (bufferOffset > 0) {
        [outputStream write:buffer length:bufferOffset];
    }
    
    ++blockIndex;
    bufferOffset = 0;
}

- (void)close {
    if (bufferOffset > 0) {
        // Write the last block if needed
        [self writeHmacBlock];
    }
    
    // Write terminating block header
    [self writeHmacBlock];
    
    [outputStream close];
}


- (NSData*)getHMACKey {
    return [HmacInputStream getHMACKey:(uint8_t*)hmacKey.bytes keylen:[hmacKey length] blockIndex:blockIndex];
}

@end
