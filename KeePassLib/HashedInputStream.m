//
//  HashedInputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "HashedInputStream.h"

@interface HashedInputStream (PrivateMethods)
- (BOOL)readHashedBlock;
@end

@implementation HashedInputStream

- (id)initWithInputStream:(InputStream*)stream {
    self = [super init];
    if (self) {
        inputStream = [stream retain];
        
        buffer = NULL;
        bufferOffset = 0;
        bufferLength = 0;
    }
    return self;
}

- (void)dealloc {
    [inputStream release];
    
    if (buffer != NULL) {
        free(buffer);
    }
    
    [super dealloc];
}

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    
    while (remaining > 0) {
        if (bufferOffset == bufferLength) {
            if (![self readHashedBlock]) {
                return bytesLength - remaining;
            }
        }
        
        int n = MIN(bufferLength - bufferOffset, remaining);
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
