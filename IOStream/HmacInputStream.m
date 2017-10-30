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
#import "HmacInputStream.h"

@interface HmacInputStream (PrivateMethods)
- (BOOL)readHmacBlock;
@end

@implementation HmacInputStream

- (id)initWithInputStream:(InputStream *)stream key:(NSData *)hkey {
    self = [super init];
    if (self) {
        inputStream = stream;
        
        buffer = NULL;
        bufferOffset = 0;
        bufferLength = 0;
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

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    
    while (remaining > 0) {
        if (bufferOffset == bufferLength) {
            if (![self readHmacBlock]) {
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

- (BOOL)readHmacBlock {
    if (eof) {
        return NO;
    }
    
    bufferOffset = 0;
    uint8_t storedHmac[32];
    uint8_t calcHmac[32];
    
    // Read the Stored header Hmac
    if ([inputStream read:storedHmac length:32] != 32) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid Header Hmac" userInfo:nil];
    }
    
    // Read the block size
    bufferLength = [inputStream readInt32];    

    // Allocate the new buffer
    if (buffer != NULL) {
        free(buffer);
    }
    buffer = malloc(bufferLength);
    
    // Read the block
    if ([inputStream read:buffer length:bufferLength] != bufferLength) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read block" userInfo:nil];
    }

    NSData *blockKey = [self getHMACKey];
    NSData *idxBytes = [Utils getUInt64Bytes:blockIndex];
    NSData *sizeBytes = [Utils getUInt32Bytes:bufferLength];
    
    // Compute the Hmac-SHA256 hash
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, blockKey.bytes, [blockKey length]);
    CCHmacUpdate(&ctx, idxBytes.bytes, [idxBytes length]);
    CCHmacUpdate(&ctx, sizeBytes.bytes, [sizeBytes length]);
    CCHmacUpdate(&ctx, buffer, bufferLength);
    CCHmacFinal(&ctx, calcHmac);
                 
    // Verify the hash
    if (memcmp(storedHmac, calcHmac, 32) != 0) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid hash" userInfo:nil];
    }

    ++blockIndex;

    // Check if it's the last block
    if (bufferLength == 0) {
        eof = true;
        return false;
    }
    
    return true;
}

- (NSData*)getHMACKey {

    return [HmacInputStream getHMACKey:(uint8_t*)hmacKey.bytes keylen:[hmacKey length] blockIndex:blockIndex];
}

+ (NSData*)getHMACKey:(uint8_t*)key keylen:(size_t)keylen blockIndex:(uint64_t)bidx {
    uint8_t hmackey[64];
    
    // Get the bytes of the block index.
    NSData *bidxBytes = [Utils getUInt64Bytes:bidx];

    CC_SHA512_CTX ctx;
    CC_SHA512_Init(&ctx);
    CC_SHA512_Update(&ctx, bidxBytes.bytes, (CC_LONG)bidxBytes.length);
    CC_SHA512_Update(&ctx, key, (CC_LONG)keylen);
    CC_SHA512_Final(hmackey, &ctx);
    
    return [[NSData alloc] initWithBytes:hmackey length:64];
}

@end
