//
//  HashedOutputData.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "HashedOutputStream.h"

@interface HashedOutputStream (PrivateMethods)
- (void)writeHashedBlock;
@end

@implementation HashedOutputStream

- (id)initWithOutputStream:(OutputStream*)stream blockSize:(uint32_t)blockSize {
    self = [super init];
    if (self) {
        outputStream = [stream retain];
        
        blockIndex = 0;
        
        buffer = malloc(blockSize);
        bufferOffset = 0;
        bufferLength = blockSize;
    }
    return self;
}

- (void)dealloc {
    [outputStream release];
    free(buffer);
    [super dealloc];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    NSUInteger length = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;
    
    while (length > 0) {
        if (bufferOffset == bufferLength) {
            [self writeHashedBlock];
        }
        
        n = MIN(bufferLength - bufferOffset, length);
        memcpy(buffer + bufferOffset, bytes + offset, n);
        
        bufferOffset += n;
        
        offset += n;
        length -= n;
    }
    
    return bytesLength;
}

- (void)writeHashedBlock {
    [outputStream writeInt32:blockIndex];
    ++blockIndex;
    
    uint8_t hash[32];
    if (bufferOffset > 0) {
        CC_SHA256(buffer, bufferOffset, hash);
    } else {
        memset(hash, 0, 32);
    }
    [outputStream write:hash length:32];
    
    [outputStream writeInt32:bufferOffset];
    
    if (bufferOffset > 0) {
        [outputStream write:buffer length:bufferOffset];
    }
    
    bufferOffset = 0;
}

- (void)close {
    if (bufferOffset > 0) {
        // Write the last block
        [self writeHashedBlock];
    }
    
    // Write terminating block
    [self writeHashedBlock];
    
    [outputStream close];
}

@end
